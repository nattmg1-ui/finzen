import 'package:flutter/material.dart';
import '../data/expense_categories.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/cycle_service.dart';

enum ExpenseFilter { todos, vital, opcional }

/// Resultado de la verificación preventiva de un gasto nuevo.
class SubcategoryAlert {
  final String subcategory;
  final int amount;
  final double averagePerCycle;

  SubcategoryAlert({required this.subcategory, required this.amount, required this.averagePerCycle});

  double get timesAverage => averagePerCycle == 0 ? 0 : amount / averagePerCycle;
}

class ExpenseController extends ChangeNotifier {
  final ExpenseService _service = ExpenseService();
  final CycleService _cycleService = CycleService();

  /// RQNF: no se registra, modifica ni elimina un gasto con fecha de
  /// 30 días o más de antigüedad.
  static const int lockAfterDays = 30;

  /// RQF: alerta preventiva cuando el gasto es igual o mayor al triple
  /// del promedio por ciclo de su subcategoría.
  static const double alertMultiplier = 3.0;
  static const int requiredCyclesForAlert = 3;

  List<ExpenseModel> _allExpenses = [];
  bool isLoading = true;
  String? errorMessage;
  ExpenseFilter filter = ExpenseFilter.todos;

  ExpenseController() {
    _listenToExpenses();
  }

  void _listenToExpenses() {
    _service.watchExpenses().listen(
      (data) {
        _allExpenses = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        errorMessage = 'No se pudieron cargar tus gastos.';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  List<ExpenseModel> get filteredExpenses {
    switch (filter) {
      case ExpenseFilter.vital:
        return _allExpenses.where((e) => e.essentialType == 'Vital').toList();
      case ExpenseFilter.opcional:
        return _allExpenses.where((e) => e.essentialType == 'Opcional').toList();
      case ExpenseFilter.todos:
        return _allExpenses;
    }
  }

  void setFilter(ExpenseFilter value) {
    filter = value;
    notifyListeners();
  }

  int get totalSpent => _allExpenses.fold(0, (sum, e) => sum + e.amount);

  Map<String, int> get totalByCategory {
    final map = <String, int>{};
    for (final e in _allExpenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  /// true si la fecha del gasto tiene 30 días o más de antigüedad.
  bool isLocked(ExpenseModel expense) {
    return DateTime.now().difference(expense.date).inDays >= lockAfterDays;
  }

  ExpenseModel? _findById(String expenseId) {
    try {
      return _allExpenses.firstWhere((e) => e.id == expenseId);
    } catch (_) {
      return null;
    }
  }

  /// Valida los datos de un gasto (mismas reglas para registrar y
  /// modificar). Devuelve el monto si todo es válido; si no, deja el
  /// motivo en errorMessage y devuelve null.
  int? validateInput({
    required String category,
    required String subcategory,
    required String amountText,
    required DateTime date,
  }) {
    final amount = int.tryParse(amountText.trim());
    if (amount == null || amount <= 0) {
      errorMessage = 'Ingresa un monto numérico mayor a cero.';
      notifyListeners();
      return null;
    }
    if (category.isEmpty || subcategory.isEmpty) {
      errorMessage = 'Selecciona categoría y subcategoría.';
      notifyListeners();
      return null;
    }
    final now = DateTime.now();
    if (date.isAfter(now)) {
      errorMessage = 'La fecha del gasto no puede ser posterior a hoy.';
      notifyListeners();
      return null;
    }
    if (now.difference(date).inDays >= lockAfterDays) {
      errorMessage = 'No puedes usar una fecha de 30 días o más de antigüedad. Elige una fecha más reciente.';
      notifyListeners();
      return null;
    }
    return amount;
  }

  /// RQF/RQNF: si la subcategoría tiene registros en cada uno de los
  /// últimos 3 ciclos completos, compara el monto contra el promedio
  /// por ciclo de esa subcategoría. Devuelve una alerta si el monto es
  /// igual o mayor al triple de ese promedio; si no, devuelve null.
  Future<SubcategoryAlert?> checkSubcategoryAlert({
    required String subcategory,
    required int amount,
  }) async {
    final cycles = await _cycleService.getPreviousCycles(requiredCyclesForAlert);
    if (cycles.length < requiredCyclesForAlert) return null;

    final totalsPerCycle = <int>[];
    for (final cycle in cycles) {
      final inCycle = _allExpenses.where((e) => e.subcategory == subcategory && cycle.contains(e.date)).toList();
      if (inCycle.isEmpty) return null; // falta historial en alguno de los 3 ciclos
      totalsPerCycle.add(inCycle.fold(0, (sum, e) => sum + e.amount));
    }

    final average = double.parse((totalsPerCycle.reduce((a, b) => a + b) / totalsPerCycle.length).toStringAsFixed(4));
    if (average <= 0) return null;

    if (amount >= average * alertMultiplier) {
      return SubcategoryAlert(subcategory: subcategory, amount: amount, averagePerCycle: average);
    }
    return null;
  }

  Future<bool> addExpense({
    required String category,
    required String subcategory,
    required String amountText,
    required String description,
    required DateTime date,
  }) async {
    final amount = validateInput(category: category, subcategory: subcategory, amountText: amountText, date: date);
    if (amount == null) return false;

    final essentialType = classifySubcategory(subcategory);

    try {
      await _service.addExpense(
        category: category,
        subcategory: subcategory,
        essentialType: essentialType,
        amount: amount,
        description: description.trim(),
        date: date,
      );
      errorMessage = null;
      return true;
    } catch (_) {
      errorMessage = 'No se pudo guardar el gasto. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editExpense({
    required String expenseId,
    required String category,
    required String subcategory,
    required String amountText,
    required String description,
    required DateTime date,
  }) async {
    final existing = _findById(expenseId);
    if (existing != null && isLocked(existing)) {
      errorMessage = 'Este gasto tiene 30 días o más de antigüedad y ya no se puede modificar.';
      notifyListeners();
      return false;
    }

    final amount = validateInput(category: category, subcategory: subcategory, amountText: amountText, date: date);
    if (amount == null) return false;

    final essentialType = classifySubcategory(subcategory);

    try {
      await _service.updateExpense(
        expenseId: expenseId,
        category: category,
        subcategory: subcategory,
        essentialType: essentialType,
        amount: amount,
        description: description.trim(),
        date: date,
      );
      errorMessage = null;
      return true;
    } catch (_) {
      errorMessage = 'No se pudo actualizar el gasto. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    final existing = _findById(expenseId);
    if (existing != null && isLocked(existing)) {
      errorMessage = 'Este gasto tiene 30 días o más de antigüedad y ya no se puede eliminar.';
      notifyListeners();
      return false;
    }

    try {
      await _service.deleteExpense(expenseId);
      return true;
    } catch (_) {
      errorMessage = 'No se pudo eliminar el gasto. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }
}
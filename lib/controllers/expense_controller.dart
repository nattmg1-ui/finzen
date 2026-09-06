import 'package:flutter/material.dart';
import '../data/expense_categories.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

enum ExpenseFilter { todos, vital, opcional }

class ExpenseController extends ChangeNotifier {
  final ExpenseService _service = ExpenseService();

  static const int lockAfterDays = 30;

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

    /// true si ya pasó un mes (o más) desde la FECHA DEL GASTO (la que
  /// el usuario eligió al registrarlo),  Así, si agregas hoy un gasto con fecha 
  //de hace 2 meses,
  /// queda bloqueado de inmediato — que es lo que se espera en la vida
  /// real (no cuándo lo tecleaste, sino cuándo ocurrió).
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

  Future<bool> addExpense({
    required String category,
    required String subcategory,
    required String amountText,
    required String description,
    required DateTime date,
  }) async {
    final amount = int.tryParse(amountText.trim());
    if (amount == null || amount < 0) {
      errorMessage = 'Ingresa un monto numérico válido (0 o mayor)';
      notifyListeners();
      return false;
    }
    if (category.isEmpty || subcategory.isEmpty) {
      errorMessage = 'Selecciona categoría y subcategoría';
      notifyListeners();
      return false;
    }
    // Misma regla que el bloqueo de edición/eliminación: no se puede
    // registrar un gasto cuya fecha ya tenga un mes o más de atraso.
    if (DateTime.now().difference(date).inDays >= lockAfterDays) {
      errorMessage = 'No puedes registrar un gasto con más de un mes de atraso. Elige una fecha más reciente.';
      notifyListeners();
      return false;
    }

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
      errorMessage = 'Este gasto ya tiene más de un mes registrado y ya no se puede modificar.';
      notifyListeners();
      return false;
    }

    final amount = int.tryParse(amountText.trim());
    if (amount == null || amount < 0) {
      errorMessage = 'Ingresa un monto numérico válido (0 o mayor)';
      notifyListeners();
      return false;
    }
    if (category.isEmpty || subcategory.isEmpty) {
      errorMessage = 'Selecciona categoría y subcategoría';
      notifyListeners();
      return false;
    }
    if (DateTime.now().difference(date).inDays >= lockAfterDays) {
      errorMessage = 'No puedes dejar un gasto con más de un mes de atraso. Elige una fecha más reciente.';
      notifyListeners();
      return false;
    }

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
      errorMessage = 'Este gasto ya tiene más de un mes registrado y ya no se puede eliminar.';
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
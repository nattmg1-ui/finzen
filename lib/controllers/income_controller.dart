import 'package:flutter/material.dart';
import '../models/income_model.dart';
import '../services/income_service.dart';

class IncomeController extends ChangeNotifier {
  final IncomeService _service = IncomeService();

  static const int lockAfterDays = 30;

  List<IncomeModel> incomes = [];
  bool isLoading = true;
  String? errorMessage;

  IncomeController() {
    _listenToIncomes();
  }

  void _listenToIncomes() {
    _service.watchIncomes().listen(
      (data) {
        incomes = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        errorMessage = 'No se pudieron cargar tus ingresos.';
        isLoading = false;
        notifyListeners();
      },
    );
  }

  int get totalMonthlyIncome => incomes.fold(0, (sum, income) => sum + income.amount);

  /// true si ya pasó un mes (o más) desde la fecha del ingreso (la
  /// que el usuario eligió), no desde que se guardó el registro.
  bool isLocked(IncomeModel income) {
    return DateTime.now().difference(income.date).inDays >= lockAfterDays;
  }

  IncomeModel? _findById(String incomeId) {
    try {
      return incomes.firstWhere((i) => i.id == incomeId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> addIncome({
    required String type,
    required String frequency,
    required String amountText,
    required DateTime date,
  }) async {
    final amount = int.tryParse(amountText.trim());
    if (amount == null || amount < 0) {
      errorMessage = 'Ingresa un monto numérico válido (0 o mayor)';
      notifyListeners();
      return false;
    }
    if (type.isEmpty || frequency.isEmpty) {
      errorMessage = 'Selecciona tipo y frecuencia';
      notifyListeners();
      return false;
    }

    try {
      await _service.addIncome(type: type, frequency: frequency, amount: amount, date: date);
      errorMessage = null;
      return true;
    } catch (_) {
      errorMessage = 'No se pudo guardar el ingreso. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editIncome({
    required String incomeId,
    required String type,
    required String frequency,
    required String amountText,
    required DateTime date,
  }) async {
    final existing = _findById(incomeId);
    if (existing != null && isLocked(existing)) {
      errorMessage = 'Este ingreso ya tiene más de un mes registrado y ya no se puede modificar.';
      notifyListeners();
      return false;
    }

    final amount = int.tryParse(amountText.trim());
    if (amount == null || amount < 0) {
      errorMessage = 'Ingresa un monto numérico válido (0 o mayor)';
      notifyListeners();
      return false;
    }
    if (type.isEmpty || frequency.isEmpty) {
      errorMessage = 'Selecciona tipo y frecuencia';
      notifyListeners();
      return false;
    }

    try {
      await _service.updateIncome(incomeId: incomeId, type: type, frequency: frequency, amount: amount, date: date);
      errorMessage = null;
      return true;
    } catch (_) {
      errorMessage = 'No se pudo actualizar el ingreso. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIncome(String incomeId) async {
    final existing = _findById(incomeId);
    if (existing != null && isLocked(existing)) {
      errorMessage = 'Este ingreso ya tiene más de un mes registrado y ya no se puede eliminar.';
      notifyListeners();
      return false;
    }

    if (incomes.length <= 1) {
      errorMessage = 'Debe existir al menos un ingreso registrado. No puedes eliminar el único que tienes.';
      notifyListeners();
      return false;
    }
    try {
      await _service.deleteIncome(incomeId);
      return true;
    } catch (_) {
      errorMessage = 'No se pudo eliminar el ingreso. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }
}
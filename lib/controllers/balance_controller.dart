import 'package:flutter/material.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/savings_goal_service.dart';

/// Combina Ingresos + Gastos + Metas para calcular el saldo general
/// disponible del usuario. No guarda nada en Firestore: se calcula
/// siempre "al vuelo" a partir de los otros 3 módulos, así que nunca
/// se desincroniza.
class BalanceController extends ChangeNotifier {
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final SavingsGoalService _goalService = SavingsGoalService();

  bool isLoading = true;

  int totalIncome = 0;
  int totalExpenses = 0;
  int totalAllocatedToGoals = 0;

  int get generalBalance => totalIncome - totalExpenses - totalAllocatedToGoals;

  bool _incomeLoaded = false;
  bool _expensesLoaded = false;
  bool _goalsLoaded = false;

  BalanceController() {
    _incomeService.watchIncomes().listen((incomes) {
      totalIncome = incomes.fold(0, (sum, i) => sum + i.amount);
      _incomeLoaded = true;
      _checkLoaded();
    });

    _expenseService.watchExpenses().listen((expenses) {
      totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
      _expensesLoaded = true;
      _checkLoaded();
    });

    _goalService.watchGoals().listen((goals) {
      // Solo las metas ACTIVAS (no completadas) cuentan como dinero
      // "apartado". Al completarse o eliminarse una meta, ese dinero
      // deja de restarse aquí automáticamente.
      totalAllocatedToGoals = goals.where((g) => !g.completed).fold(0, (sum, g) => sum + g.currentAmount);
      _goalsLoaded = true;
      _checkLoaded();
    });
  }

  void _checkLoaded() {
    if (_incomeLoaded && _expensesLoaded && _goalsLoaded) {
      isLoading = false;
    }
    notifyListeners();
  }
}
import 'package:flutter/material.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/savings_goal_service.dart';
import '../services/firestore_service.dart';
import '../models/savings_goal_model.dart';

/// Alimenta la pantalla de Inicio: saldo general, top categorías de
/// gasto, y la meta de ahorro principal — combinando Ingresos, Gastos
/// y Metas en un solo lugar, igual que el maquetado.
class HomeController extends ChangeNotifier {
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final SavingsGoalService _goalService = SavingsGoalService();
  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = true;
  String userName = 'Usuario';

  int totalIncome = 0;
  int totalExpenses = 0;
  int _totalAllocatedToGoals = 0;
  Map<String, int> categoryTotals = {};
  List<SavingsGoalModel> goals = [];

  bool _incomeLoaded = false;
  bool _expensesLoaded = false;
  bool _goalsLoaded = false;

  HomeController() {
    _firestoreService.watchCurrentUserProfile().listen((user) {
      if (user != null && user.name.isNotEmpty) {
        userName = user.name;
        notifyListeners();
      }
    });

    _incomeService.watchIncomes().listen((incomes) {
      totalIncome = incomes.fold(0, (sum, i) => sum + i.amount);
      _incomeLoaded = true;
      _checkLoaded();
    });

    _expenseService.watchExpenses().listen((expenses) {
      totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);
      final map = <String, int>{};
      for (final e in expenses) {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
      categoryTotals = map;
      _expensesLoaded = true;
      _checkLoaded();
    });

    _goalService.watchGoals().listen((data) {
      goals = data;
      _totalAllocatedToGoals = data.where((g) => !g.completed).fold(0, (sum, g) => sum + g.currentAmount);
      _goalsLoaded = true;
      _checkLoaded();
    });
  }

  void _checkLoaded() {
    if (_incomeLoaded && _expensesLoaded && _goalsLoaded) isLoading = false;
    notifyListeners();
  }

  int get generalBalance => totalIncome - totalExpenses - _totalAllocatedToGoals;

  List<MapEntry<String, int>> get topCategories {
    final entries = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }

  SavingsGoalModel? get topGoal {
    final active = goals.where((g) => !g.completed).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) {
      const order = {'Alta': 0, 'Media': 1, 'Baja': 2};
      final rankA = order[a.priority] ?? 3;
      final rankB = order[b.priority] ?? 3;
      if (rankA != rankB) return rankA.compareTo(rankB);
      return b.progress.compareTo(a.progress);
    });
    return active.first;
  }
}
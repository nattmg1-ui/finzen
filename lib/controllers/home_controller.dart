import 'package:flutter/material.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/savings_goal_service.dart';
import '../services/firestore_service.dart';
import '../services/cycle_service.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../models/savings_goal_model.dart';

/// Alimenta la pantalla de Inicio:
/// - Saldo general (acumulado): todos los ingresos - todos los gastos -
///   dinero apartado en metas activas.
/// - Ingresos y gastos del ciclo actual.
/// - Top 3 categorías de gasto y la meta de ahorro principal.
class HomeController extends ChangeNotifier {
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final SavingsGoalService _goalService = SavingsGoalService();
  final FirestoreService _firestoreService = FirestoreService();
  final CycleService _cycleService = CycleService();

  bool isLoading = true;
  String userName = 'Usuario';

  List<IncomeModel> _incomes = [];
  List<ExpenseModel> _expenses = [];
  List<SavingsGoalModel> goals = [];

  int cycleIncome = 0;
  int cycleExpenses = 0;

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

    _incomeService.watchIncomes().listen((data) {
      _incomes = data;
      _incomeLoaded = true;
      _refresh();
    });

    _expenseService.watchExpenses().listen((data) {
      _expenses = data;
      _expensesLoaded = true;
      _refresh();
    });

    _goalService.watchGoals().listen((data) {
      goals = data;
      _goalsLoaded = true;
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (_incomeLoaded && _expensesLoaded) {
      final currentCycle = await _cycleService.getCurrentCycle();
      if (currentCycle != null) {
        cycleIncome = _incomes.where((i) => currentCycle.contains(i.date)).fold(0, (sum, i) => sum + i.amount);
        cycleExpenses = _expenses.where((e) => currentCycle.contains(e.date)).fold(0, (sum, e) => sum + e.amount);
      } else {
        cycleIncome = 0;
        cycleExpenses = 0;
      }
    }
    if (_incomeLoaded && _expensesLoaded && _goalsLoaded) isLoading = false;
    notifyListeners();
  }

  int get totalIncome => _incomes.fold(0, (sum, i) => sum + i.amount);
  int get totalExpenses => _expenses.fold(0, (sum, e) => sum + e.amount);
  int get _totalAllocatedToGoals => goals.where((g) => !g.completed).fold(0, (sum, g) => sum + g.currentAmount);

  /// Saldo general acumulado.
  int get generalBalance => totalIncome - totalExpenses - _totalAllocatedToGoals;

  List<MapEntry<String, int>> get topCategories {
    final map = <String, int>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
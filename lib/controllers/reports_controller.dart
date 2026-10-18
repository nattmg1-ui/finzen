import 'package:flutter/material.dart';
import '../models/cycle_info.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/savings_goal_model.dart';
import '../services/cycle_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/firestore_service.dart';
import '../services/savings_goal_service.dart';
import '../services/reference_income_service.dart';

/// Gasto de un ciclo con su promedio móvil de 3 ciclos (reporte de Empleado).
class CycleSpendingPoint {
  final String label;
  final int spent;
  final double? movingAverage;

  CycleSpendingPoint({required this.label, required this.spent, this.movingAverage});
}

/// Ingresos de un ciclo separados por fuente (reporte de Mixto).
class CycleIncomeBar {
  final String label;
  final Map<String, int> amountByType;

  CycleIncomeBar({required this.label, required this.amountByType});

  int get total => amountByType.values.fold(0, (sum, v) => sum + v);
}

/// Datos del Módulo 7 (Reportes), calculados sobre el ciclo actual.
class ReportsController extends ChangeNotifier {
  final CycleService _cycleService = CycleService();
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final SavingsGoalService _goalService = SavingsGoalService();
  final FirestoreService _firestoreService = FirestoreService();
  final ReferenceIncomeService _referenceIncomeService = ReferenceIncomeService();

  /// RQNF: visualizaciones avanzadas con al menos 30 registros de gasto.
  static const int minRecordsForAdvanced = 30;
  static const int historyCyclesShown = 6;
  static const int movingAverageWindow = 3;
  static const double safetyReserveRatio = 0.20;

  static const List<String> _monthAbbr = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  bool isLoading = true;
  String? profile;

  List<IncomeModel> _incomes = [];
  List<ExpenseModel> _expenses = [];
  List<SavingsGoalModel> _goals = [];
  List<String> _diagnosisIncomeTypes = [];

  CycleInfo? currentCycle;
  int cycleIncome = 0;
  int cycleSpent = 0;
  Map<String, int> _cycleCategoryTotals = {};
  Map<String, int> _cycleVitalCategoryTotals = {};
  List<CycleSpendingPoint> spendingHistory = [];
  double? averageSpentLastCycles;
  List<CycleIncomeBar> incomeBySource = [];
  List<ExpenseModel> scatterExpenses = [];
  ReferenceIncome? referenceIncome;

  bool _incomesLoaded = false;
  bool _expensesLoaded = false;
  bool _goalsLoaded = false;
  bool _computing = false;
  bool _pending = false;

  ReportsController() {
    _incomeService.watchIncomes().listen((data) {
      _incomes = data;
      _incomesLoaded = true;
      _scheduleCompute();
    });

    _expenseService.watchExpenses().listen((data) {
      _expenses = data;
      _expensesLoaded = true;
      _scheduleCompute();
    });

    _goalService.watchGoals().listen((data) {
      _goals = data;
      _goalsLoaded = true;
      _scheduleCompute();
    });

    _firestoreService.fetchCurrentUserProfile().then((user) {
      final raw = user?.diagnosis?['incomeSourceType'];
      if (raw is List) {
        _diagnosisIncomeTypes = raw.map((e) => e.toString()).toList();
      }
      _scheduleCompute();
    });
  }

  Future<void> _scheduleCompute() async {
    if (!(_incomesLoaded && _expensesLoaded && _goalsLoaded)) return;
    if (_computing) {
      _pending = true;
      return;
    }
    _computing = true;
    try {
      do {
        _pending = false;
        await _compute();
      } while (_pending);
    } finally {
      _computing = false;
    }
    isLoading = false;
    notifyListeners();
  }

  String? _profileFromDiagnosis() {
    if (_diagnosisIncomeTypes.isEmpty) return null;
    return _diagnosisIncomeTypes.length > 1 ? 'Mixto' : _diagnosisIncomeTypes.first;
  }

  int _incomeIn(CycleInfo c) => _incomes.where((i) => c.contains(i.date)).fold(0, (sum, i) => sum + i.amount);

  List<ExpenseModel> _expensesIn(CycleInfo c) => _expenses.where((e) => c.contains(e.date)).toList();

  int _spentIn(CycleInfo c) => _expensesIn(c).fold(0, (sum, e) => sum + e.amount);

  Future<void> _compute() async {
    profile = await _cycleService.effectiveProfile() ?? _profileFromDiagnosis();
    currentCycle = await _cycleService.getCurrentCycle();
    final previous = await _cycleService.getPreviousCycles(historyCyclesShown); // más reciente primero
    referenceIncome = await _referenceIncomeService.compute();

    final cycle = currentCycle;
    if (cycle == null) {
      cycleIncome = 0;
      cycleSpent = 0;
      _cycleCategoryTotals = {};
      _cycleVitalCategoryTotals = {};
      spendingHistory = [];
      averageSpentLastCycles = null;
      incomeBySource = [];
      scatterExpenses = [];
      return;
    }

    final useMonthLabels = profile != null && _cycleService.usesCalendarMonth(profile!);
    String label(CycleInfo c) => useMonthLabels ? _monthAbbr[c.start.month - 1] : '${c.start.day}/${c.start.month}';

    // Ciclo actual.
    cycleIncome = _incomeIn(cycle);
    final inCycle = _expensesIn(cycle);
    cycleSpent = inCycle.fold(0, (sum, e) => sum + e.amount);

    final all = <String, int>{};
    final vital = <String, int>{};
    for (final e in inCycle) {
      all[e.category] = (all[e.category] ?? 0) + e.amount;
      if (e.essentialType == 'Vital') {
        vital[e.category] = (vital[e.category] ?? 0) + e.amount;
      }
    }
    _cycleCategoryTotals = all;
    _cycleVitalCategoryTotals = vital;

    // Historial en orden cronológico (más antiguo primero) + ciclo actual.
    final chronological = [...previous.reversed, cycle];
    final spentPerCycle = chronological.map(_spentIn).toList();

    spendingHistory = [
      for (var i = 0; i < chronological.length; i++)
        CycleSpendingPoint(
          label: label(chronological[i]),
          spent: spentPerCycle[i],
          movingAverage: i >= movingAverageWindow - 1
              ? spentPerCycle.sublist(i - movingAverageWindow + 1, i + 1).reduce((a, b) => a + b) / movingAverageWindow
              : null,
        ),
    ];

    final completed = previous.take(movingAverageWindow).toList();
    averageSpentLastCycles =
        completed.isEmpty ? null : completed.map(_spentIn).reduce((a, b) => a + b) / completed.length;

    incomeBySource = [
      for (final c in chronological)
        CycleIncomeBar(
          label: label(c),
          amountByType: {
            for (final i in _incomes.where((i) => c.contains(i.date)))
              i.type: (_incomes.where((x) => c.contains(x.date) && x.type == i.type).fold(0, (sum, x) => sum + x.amount)),
          },
        ),
    ];

    final historyStart = chronological.first.start;
    scatterExpenses = _expenses.where((e) => !e.date.isBefore(historyStart) && e.date.isBefore(cycle.end)).toList();
  }

  String? get effectiveIncomeType => profile;

  bool get hasEnoughRecordsForAdvanced => _expenses.length >= minRecordsForAdvanced;
  int get totalExpenseRecords => _expenses.length;

  /// RQNF: si los gastos del ciclo superan su ingreso, los reportes se
  /// enfocan en liquidez y se ocultan los componentes de deseos e inversión.
  bool get isLiquidityAtRisk => cycleSpent > 0 && cycleSpent > cycleIncome;

  Map<String, int> get categoryTotals => isLiquidityAtRisk ? _cycleVitalCategoryTotals : _cycleCategoryTotals;

  int get cycleRemaining => cycleIncome - cycleSpent;

  double get savingsProgressPercent {
    final active = _goals.where((g) => !g.completed);
    final target = active.fold(0, (sum, g) => sum + g.targetAmount);
    final current = active.fold(0, (sum, g) => sum + g.currentAmount);
    if (target == 0) return 0;
    return (current / target).clamp(0, 1).toDouble();
  }

  /// Días que faltan para el siguiente ingreso (fin del ciclo actual).
  int get daysRemainingInCycle {
    final c = currentCycle;
    if (c == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(c.end.year, c.end.month, c.end.day);
    final days = end.difference(today).inDays;
    return days < 0 ? 0 : days;
  }

  int get safetyBase => referenceIncome?.amount ?? 0;
  int get safetyReserve => (safetyBase * safetyReserveRatio).round();
  int get safetySpendingCap => safetyBase - safetyReserve;
}
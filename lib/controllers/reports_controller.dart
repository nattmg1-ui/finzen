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
import '../services/safety_base_income_service.dart';
import '../services/financial_mode_service.dart';

/// Gasto de un ciclo con su promedio móvil de 3 ciclos (reporte de Empleado).
class CycleSpendingPoint {
  final String label;
  final int spent;
  final double? movingAverage;

  CycleSpendingPoint({required this.label, required this.spent, this.movingAverage});
}

/// Datos del Módulo 7 (Reportes), calculados sobre el ciclo actual.
class ReportsController extends ChangeNotifier {
  final CycleService _cycleService = CycleService();
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final SavingsGoalService _goalService = SavingsGoalService();
  final FirestoreService _firestoreService = FirestoreService();
  final ReferenceIncomeService _referenceIncomeService = ReferenceIncomeService();
  final SafetyBaseIncomeService _safetyBaseIncomeService = SafetyBaseIncomeService();
  final FinancialModeService _financialModeService = FinancialModeService();

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
  /// Mixto: total registrado de cada tipo de fuente en el ciclo actual,
  /// de mayor a menor.
  List<MapEntry<String, int>> incomeBySourceCurrent = [];
  List<ExpenseModel> scatterExpenses = [];
  ReferenceIncome? referenceIncome;
  bool _survivalMode = false;

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
    // RQNF: el motor de recomendaciones determina el enfoque de supervivencia
    // cada vez que cambian los ingresos o los gastos.
    _survivalMode = (await _financialModeService.evaluate()).isSurvivalMode;
    final previous = await _cycleService.getPreviousCycles(historyCyclesShown); // más reciente primero
    // Presupuesto de seguridad: usa el IBS si existe (referencia conservadora);
    // si no, el ingreso de referencia del ciclo.
    final safetyBaseIncome = await _safetyBaseIncomeService.computeSafetyBaseIncome();
    referenceIncome = safetyBaseIncome != null
        ? ReferenceIncome(amount: safetyBaseIncome, source: ReferenceIncomeSource.safetyBase)
        : await _referenceIncomeService.compute();

    final cycle = currentCycle;
    if (cycle == null) {
      cycleIncome = 0;
      cycleSpent = 0;
      _cycleCategoryTotals = {};
      _cycleVitalCategoryTotals = {};
      spendingHistory = [];
      averageSpentLastCycles = null;
      incomeBySourceCurrent = [];
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

    final byType = <String, int>{};
    for (final i in _incomes.where((i) => cycle.contains(i.date))) {
      byType[i.type] = (byType[i.type] ?? 0) + i.amount;
    }
    incomeBySourceCurrent = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final historyStart = chronological.first.start;
    scatterExpenses = _expenses.where((e) => !e.date.isBefore(historyStart) && e.date.isBefore(cycle.end)).toList();
  }

  String? get effectiveIncomeType => profile;

  bool get hasEnoughRecordsForAdvanced => _expenses.length >= minRecordsForAdvanced;
  int get totalExpenseRecords => _expenses.length;

  /// Enfoque de liquidez y supervivencia, determinado por el motor de
  /// recomendaciones (Módulo 8).
  bool get isLiquidityAtRisk => _survivalMode;

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
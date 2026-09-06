import 'package:flutter/material.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/firestore_service.dart';
import '../services/savings_goal_service.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';

/// Combina Ingresos + Gastos + Metas + tipo de ingreso (del
/// diagnóstico) para alimentar el Módulo 7 (Reportes).
class ReportsController extends ChangeNotifier {
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final FirestoreService _firestoreService = FirestoreService();
  final SavingsGoalService _goalService = SavingsGoalService();

  /// RQNF: proyecciones/visualizaciones avanzadas solo se habilitan
  /// con al menos 30 registros de gasto acumulados.
  static const int minRecordsForAdvanced = 30;

  bool isLoading = true;
  List<IncomeModel> incomes = [];
  List<ExpenseModel> expenses = [];

  /// Hasta 2 tipos que el usuario contestó en el diagnóstico. Solo se
  /// usa como respaldo mientras todavía no tiene ingresos reales
  /// registrados — ver effectiveIncomeType más abajo.
  List<String> diagnosisIncomeTypes = [];

  int _goalsCurrentTotal = 0;
  int _goalsTargetTotal = 0;

  bool _incomesLoaded = false;
  bool _expensesLoaded = false;
  bool _goalsLoaded = false;

  ReportsController() {
    _incomeService.watchIncomes().listen((data) {
      incomes = data;
      _incomesLoaded = true;
      _checkLoaded();
    });

    _expenseService.watchExpenses().listen((data) {
      expenses = data;
      _expensesLoaded = true;
      _checkLoaded();
    });

    _goalService.watchGoals().listen((goals) {
      final active = goals.where((g) => !g.completed);
      _goalsCurrentTotal = active.fold(0, (sum, g) => sum + g.currentAmount);
      _goalsTargetTotal = active.fold(0, (sum, g) => sum + g.targetAmount);
      _goalsLoaded = true;
      _checkLoaded();
    });

    _firestoreService.fetchCurrentUserProfile().then((user) {
      final raw = user?.diagnosis?['incomeSourceType'];
      if (raw is List) {
        diagnosisIncomeTypes = raw.map((e) => e.toString()).toList();
      }
      notifyListeners();
    });
  }

  void _checkLoaded() {
    if (_incomesLoaded && _expensesLoaded && _goalsLoaded) isLoading = false;
    notifyListeners();
  }

  int get totalIncome => incomes.fold(0, (sum, i) => sum + i.amount);
  int get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);

  /// El perfil que usan las gráficas: si ya hay ingresos REGISTRADOS,
  /// manda lo que realmente registraste (si son de más de un tipo,
  /// se trata como "Mixto"), sin importar lo que dijiste en el
  /// diagnóstico. Solo si todavía no registras ningún ingreso, se usa
  /// la respuesta del diagnóstico como punto de partida.
  String? get effectiveIncomeType {
    final registeredTypes = incomes.map((i) => i.type).toSet();
    if (registeredTypes.isNotEmpty) {
      return registeredTypes.length > 1 ? 'Mixto' : registeredTypes.first;
    }
    if (diagnosisIncomeTypes.isNotEmpty) {
      return diagnosisIncomeTypes.length > 1 ? 'Mixto' : diagnosisIncomeTypes.first;
    }
    return null;
  }

  /// RQNF: si los gastos superan al ingreso, el sistema se enfoca en
  /// liquidez/supervivencia y oculta "deseos" (gasto Opcional).
  bool get isLiquidityAtRisk => totalIncome > 0 && totalExpenses > totalIncome;

  bool get hasEnoughRecordsForAdvanced => expenses.length >= minRecordsForAdvanced;

  Map<String, int> get categoryTotals {
    final map = <String, int>{};
    for (final e in expenses) {
      if (isLiquidityAtRisk && e.essentialType != 'Vital') continue;
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  /// Progreso de ahorro agregado (todas las metas activas), usado en
  /// el reporte de perfiles de ingreso fijo (Mesada/Empleado).
  double get savingsProgressPercent {
    if (_goalsTargetTotal == 0) return 0;
    return (_goalsCurrentTotal / _goalsTargetTotal).clamp(0, 1);
  }

  /// Días restantes del mes en curso, como proxy simple de "días
  /// restantes para el siguiente ingreso" en perfiles fijos.
  int get daysRemainingInPeriod {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayOfMonth.day - now.day;
  }

  /// Colchón de seguridad sugerido para ingresos variables: 20% del
  /// ingreso total registrado.
  int get suggestedSafetyBudget => (totalIncome * 0.20).round();

  List<ExpenseModel> get expensesSortedByDate {
    final sorted = [...expenses];
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  /// Total registrado por cada fuente de ingreso, usado en el reporte
  /// de perfil "Mixto".
  Map<String, int> get incomeSourceBreakdown {
    final map = <String, int>{};
    for (final i in incomes) {
      map[i.type] = (map[i.type] ?? 0) + i.amount;
    }
    return map;
  }
}
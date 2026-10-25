import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';
import 'income_service.dart';
import 'firestore_service.dart';
import 'safety_base_income_service.dart';

/// Montos que usa el Módulo 5 (Metas de ahorro), expresados por mes.
/// La regla del 20% da el mismo resultado por mes que por ciclo, porque
/// cuota e ingreso se convierten con el mismo factor.
/// - Ingreso: el registrado en el ciclo actual convertido a mensual
///   (semanal x4.33, quincenal x2, mensual o mes calendario x1). Para
///   perfiles Freelance o Mixto (RQNF del Módulo 5): Ingreso Base de
///   Seguridad si está disponible; si no, el ingreso del ciclo; y si
///   tampoco hay ingreso en el ciclo, lo declarado en el diagnóstico.
/// - Gastos básicos: promedio del Cubo A (Vital) de los últimos 3 ciclos
///   completos, convertido a mensual. Si todavía no hay ciclos completos,
///   se usa lo declarado en el diagnóstico.
class MonthlyBudgetService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();
  final IncomeService _incomeService = IncomeService();
  final FirestoreService _firestoreService = FirestoreService();
  final SafetyBaseIncomeService _safetyBaseIncomeService = SafetyBaseIncomeService();

  static const int basicExpensesCycles = 3;

  /// Cuántos ciclos caben en un mes, según el perfil y la frecuencia.
  Future<double> cyclesPerMonth() async {
    final profile = await _cycleService.effectiveProfile();
    if (profile == null || _cycleService.usesCalendarMonth(profile)) return 1;

    final incomes = await _incomeService.fetchIncomesOnce();
    final main = incomes.reduce((a, b) => a.amount >= b.amount ? a : b);
    switch (main.frequency) {
      case 'Semanal':
        return 52 / 12;
      case 'Quincenal':
        return 2;
      default:
        return 1;
    }
  }

  Future<int> monthlyIncome() async {
    final profile = await _cycleService.effectiveProfile();
    final isVariable = profile == 'Freelance' || profile == 'Mixto';

    // RQNF: Freelance o Mixto con IBS disponible usan el IBS.
    if (isVariable) {
      final safetyBase = await _safetyBaseIncomeService.computeSafetyBaseIncome();
      if (safetyBase != null) return safetyBase;
    }

    final currentCycle = await _cycleService.getCurrentCycle();
    final cycleIncome = currentCycle == null ? 0 : await _cycleService.incomeInCycle(currentCycle);

    // RQNF: Freelance o Mixto sin IBS ni ingreso en el ciclo usan el diagnóstico.
    if (isVariable && cycleIncome <= 0) {
      final user = await _firestoreService.fetchCurrentUserProfile();
      return (user?.diagnosis?['monthlyIncome'] as num?)?.toInt() ?? 0;
    }

    final factor = await cyclesPerMonth();
    return (cycleIncome * factor).round();
  }

  Future<int> monthlyBasicExpenses() async {
    final cycles = await _cycleService.getPreviousCycles(basicExpensesCycles);

    if (cycles.isEmpty) {
      final user = await _firestoreService.fetchCurrentUserProfile();
      return (user?.diagnosis?['monthlyBasicExpenses'] as num?)?.toInt() ?? 0;
    }

    var total = 0;
    for (final cycle in cycles) {
      final aggregate = await _aggregateService.aggregateForCycle(cycle);
      total += aggregate.cuboA;
    }
    final averagePerCycle = total / cycles.length;
    final factor = await cyclesPerMonth();
    return (averagePerCycle * factor).round();
  }
}

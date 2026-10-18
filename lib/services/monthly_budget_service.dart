import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';
import 'income_service.dart';
import 'firestore_service.dart';
import 'reference_income_service.dart';

/// Montos mensuales que usa el Módulo 5 (Metas de ahorro):
/// - Ingreso mensual: ingreso de referencia del ciclo actual convertido
///   a mensual (semanal x4.33, quincenal x2, mensual x1). Si la
///   referencia es el Ingreso Base de Seguridad o el diagnóstico, ya es
///   un monto mensual y se usa tal cual.
/// - Gastos básicos mensuales: promedio del Cubo A (Vital) de los
///   últimos 3 ciclos completos, convertido a mensual. Si todavía no hay
///   ciclos completos, se usa lo declarado en el diagnóstico.
class MonthlyBudgetService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();
  final IncomeService _incomeService = IncomeService();
  final FirestoreService _firestoreService = FirestoreService();
  final ReferenceIncomeService _referenceIncomeService = ReferenceIncomeService();

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
    final reference = await _referenceIncomeService.compute();
    if (reference.source != ReferenceIncomeSource.cycle) return reference.amount;
    final factor = await cyclesPerMonth();
    return (reference.amount * factor).round();
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
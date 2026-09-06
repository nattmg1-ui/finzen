import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';
import 'income_service.dart';

class FinancialModeResult {
  final bool isContingencyMode;
  final bool isStabilityMode;

  FinancialModeResult({required this.isContingencyMode, required this.isStabilityMode});
}

/// Detecta dos "modos" especiales que cambian el comportamiento del
/// motor de recomendaciones:
///
/// - Contingencia: perfil Freelance sin actividad de ingreso este
///   ciclo (ver nota de diseño en el código: como los ingresos son
///   fuentes recurrentes y no transacciones por ciclo, se usa "no se
///   registró/editó ninguna fuente de ingreso dentro de este ciclo"
///   como la señal más cercana disponible).
/// - Estabilidad: los gastos Vitales (Cubo A) de este ciclo superan
///   el ingreso disponible de este ciclo.
class FinancialModeService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();
  final IncomeService _incomeService = IncomeService();

  Future<String?> _effectiveIncomeType() async {
    final incomes = await _incomeService.watchIncomes().first;
    final types = incomes.map((i) => i.type).toSet();
    if (types.isEmpty) return null;
    return types.length > 1 ? 'Mixto' : types.first;
  }

  Future<FinancialModeResult> evaluate() async {
    final profile = await _effectiveIncomeType();
    final currentCycle = await _cycleService.getCurrentCycle();

    var isContingency = false;
    if (profile == 'Freelance' && currentCycle != null) {
      final incomes = await _incomeService.watchIncomes().first;
      final hasIncomeActivityThisCycle = incomes.any((i) => currentCycle.contains(i.date));
      isContingency = !hasIncomeActivityThisCycle;
    }

    var isStability = false;
    if (currentCycle != null) {
      final aggregate = await _aggregateService.aggregateForCycle(currentCycle);
      final incomeSnapshot = await _cycleService.totalIncomeAsOf(currentCycle.end);
      isStability = incomeSnapshot > 0 && aggregate.cuboA > incomeSnapshot;
    }

    return FinancialModeResult(isContingencyMode: isContingency, isStabilityMode: isStability);
  }
}
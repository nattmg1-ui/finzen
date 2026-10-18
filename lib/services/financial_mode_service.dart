import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';
import 'reference_income_service.dart';

class FinancialModeResult {
  final bool isContingencyMode;
  final bool isStabilityMode;

  FinancialModeResult({required this.isContingencyMode, required this.isStabilityMode});
}

/// Modos especiales del motor de recomendaciones:
/// - Contingencia: perfil exclusivamente Freelance sin ingresos
///   registrados dentro del ciclo actual. Se desactiva en cuanto
///   registra un ingreso en el ciclo o su perfil deja de ser solo Freelance.
/// - Estabilidad: los gastos esenciales (Cubo A) del ciclo actual
///   superan el ingreso de referencia. Se desactiva en la siguiente
///   evaluación en la que ya no lo superen.
class FinancialModeService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();
  final ReferenceIncomeService _referenceIncomeService = ReferenceIncomeService();

  Future<FinancialModeResult> evaluate() async {
    final currentCycle = await _cycleService.getCurrentCycle();
    if (currentCycle == null) {
      return FinancialModeResult(isContingencyMode: false, isStabilityMode: false);
    }

    final profile = await _cycleService.effectiveProfile();
    final currentIncome = await _cycleService.incomeInCycle(currentCycle);
    final isContingency = profile == 'Freelance' && currentIncome <= 0;

    final reference = await _referenceIncomeService.compute();
    final aggregate = await _aggregateService.aggregateForCycle(currentCycle);
    final isStability = reference.amount > 0 && aggregate.cuboA > reference.amount;

    return FinancialModeResult(isContingencyMode: isContingency, isStabilityMode: isStability);
  }
}
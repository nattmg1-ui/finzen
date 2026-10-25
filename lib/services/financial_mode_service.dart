import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';

class FinancialModeResult {
  final bool isContingencyMode;
  final bool isStabilityMode;

  /// Enfoque de liquidez y supervivencia (se muestra solo en Reportes).
  final bool isSurvivalMode;

  FinancialModeResult({
    required this.isContingencyMode,
    required this.isStabilityMode,
    required this.isSurvivalMode,
  });
}

/// Modos especiales del motor de recomendaciones:
/// - Contingencia: perfil exclusivamente Freelance sin ingresos
///   registrados dentro del ciclo actual. Se desactiva en cuanto
///   registra un ingreso en el ciclo o su perfil deja de ser solo Freelance.
/// - Estabilidad: los gastos esenciales (Cubo A) del ciclo actual
///   superan el ingreso registrado en ese mismo ciclo. Se desactiva en la
///   siguiente evaluación en la que ya no lo superen.
/// - Supervivencia: el gasto total del ciclo actual (Vital + Opcional)
///   supera el ingreso registrado en ese ciclo y dicho ingreso es mayor
///   a cero. Lo usa la pantalla de Reportes (Módulo 7).
class FinancialModeService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();

  Future<FinancialModeResult> evaluate() async {
    final currentCycle = await _cycleService.getCurrentCycle();
    if (currentCycle == null) {
      return FinancialModeResult(isContingencyMode: false, isStabilityMode: false, isSurvivalMode: false);
    }

    final profile = await _cycleService.effectiveProfile();
    final currentIncome = await _cycleService.incomeInCycle(currentCycle);
    final isContingency = profile == 'Freelance' && currentIncome <= 0;

    // RQF: el Cubo A se compara contra el ingreso disponible del ciclo actual.
    final aggregate = await _aggregateService.aggregateForCycle(currentCycle);
    final isStability = currentIncome > 0 && aggregate.cuboA > currentIncome;

    // RQNF (Módulo 7): gasto total del ciclo > ingreso del ciclo, con ingreso > 0.
    final isSurvival = currentIncome > 0 && aggregate.totalSpent > currentIncome;

    return FinancialModeResult(
      isContingencyMode: isContingency,
      isStabilityMode: isStability,
      isSurvivalMode: isSurvival,
    );
  }
}

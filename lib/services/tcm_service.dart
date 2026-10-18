import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';

class TcmResult {
  final double tcm;
  final int incomeDelta;
  final int discretionaryDelta;
  final bool exceedsThreshold;

  TcmResult({
    required this.tcm,
    required this.incomeDelta,
    required this.discretionaryDelta,
    required this.exceedsThreshold,
  });
}

/// Tasa de Consumo Marginal: TCM = ΔGasto discrecional / ΔIngreso,
/// comparando el ciclo actual contra el inmediato anterior.
class TcmService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();

  static const double alertThreshold = 0.5;

  double _round4(double value) => double.parse(value.toStringAsFixed(4));

  /// Devuelve null cuando no se cumple alguna condición del documento;
  /// en ese caso la sección de TCM no se muestra.
  Future<TcmResult?> computeTcm() async {
    final currentCycle = await _cycleService.getCurrentCycle();
    final previousCycles = await _cycleService.getPreviousCycles(1);
    if (currentCycle == null || previousCycles.isEmpty) return null;
    final previousCycle = previousCycles.first;

    final currentIncome = await _cycleService.incomeInCycle(currentCycle);
    final previousIncome = await _cycleService.incomeInCycle(previousCycle);
    final previousAgg = await _aggregateService.aggregateForCycle(previousCycle);

    // RQNF: debe existir un ciclo anterior con ingreso y gasto discrecional registrados.
    if (previousIncome <= 0 || previousAgg.cuboB <= 0) return null;

    // RQNF: la diferencia de ingreso debe ser positiva.
    final incomeDelta = currentIncome - previousIncome;
    if (incomeDelta <= 0) return null;

    final currentAgg = await _aggregateService.aggregateForCycle(currentCycle);
    final discretionaryDelta = currentAgg.cuboB - previousAgg.cuboB;

    final tcm = _round4(discretionaryDelta / incomeDelta);

    return TcmResult(
      tcm: tcm,
      incomeDelta: incomeDelta,
      discretionaryDelta: discretionaryDelta,
      exceedsThreshold: tcm > alertThreshold,
    );
  }
}
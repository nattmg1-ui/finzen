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

class TcmService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();

  static const double alertThreshold = 0.5;

  double _round4(double value) => double.parse(value.toStringAsFixed(4));

  Future<TcmResult?> computeTcm() async {
    final currentCycle = await _cycleService.getCurrentCycle();
    final previousCycles = await _cycleService.getPreviousCycles(1);
    if (currentCycle == null || previousCycles.isEmpty) return null;
    final previousCycle = previousCycles.first;

    final currentIncome = await _cycleService.totalIncomeAsOf(currentCycle.end);
    final previousIncome = await _cycleService.totalIncomeAsOf(previousCycle.end);
    final incomeDelta = currentIncome - previousIncome;

    if (incomeDelta <= 0) return null;

    final currentAgg = await _aggregateService.aggregateForCycle(currentCycle);
    final previousAgg = await _aggregateService.aggregateForCycle(previousCycle);
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
import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';
import 'firestore_service.dart';
import 'monthly_budget_service.dart';

class ExponentialSmoothingResult {
  final double projection;

  /// true mientras el primer ciclo del usuario no ha terminado: en ese
  /// caso la proyección es S₀ (lo declarado en el diagnóstico).
  final bool isCalibrating;

  ExponentialSmoothingResult({required this.projection, required this.isCalibrating});
}

/// Proyección del gasto al cierre del ciclo actual:
/// Sₜ = 0.3 × Xₜ + 0.7 × Sₜ₋₁
/// - S₀ = gasto mensual estimado del diagnóstico, convertido al tamaño
///   del ciclo del usuario (quincenal: /2, semanal: /4.33).
/// - El primer cálculo formal ocurre al cierre del primer ciclo.
class ExponentialSmoothingService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();
  final FirestoreService _firestoreService = FirestoreService();
  final MonthlyBudgetService _budgetService = MonthlyBudgetService();

  static const double alpha = 0.3;

  double _round4(double value) => double.parse(value.toStringAsFixed(4));

  Future<double> _initialProjection() async {
    final user = await _firestoreService.fetchCurrentUserProfile();
    final monthly = (user?.diagnosis?['monthlyBasicExpenses'] as num?)?.toDouble() ?? 0;
    final cyclesPerMonth = await _budgetService.cyclesPerMonth();
    return monthly / cyclesPerMonth;
  }

  Future<ExponentialSmoothingResult> computeProjection() async {
    final s0 = await _initialProjection();

    final currentCycle = await _cycleService.getCurrentCycle();
    final previousCycles = await _cycleService.getAllPreviousCycles(); // del más reciente al más antiguo

    // RQNF: el primer ciclo debe haber terminado antes del primer cálculo formal.
    if (currentCycle == null || previousCycles.isEmpty) {
      return ExponentialSmoothingResult(projection: _round4(s0), isCalibrating: true);
    }

    double s = s0;
    for (final cycle in previousCycles.reversed) {
      final aggregate = await _aggregateService.aggregateForCycle(cycle);
      s = _round4(alpha * aggregate.totalSpent + (1 - alpha) * s);
    }

    final currentAggregate = await _aggregateService.aggregateForCycle(currentCycle);
    final projection = _round4(alpha * currentAggregate.totalSpent + (1 - alpha) * s);

    return ExponentialSmoothingResult(projection: projection, isCalibrating: false);
  }
}
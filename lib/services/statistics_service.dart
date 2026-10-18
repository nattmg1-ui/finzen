import 'dart:math' as math;
import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';

/// Resultado del WMA para una categoría.
class CategoryWmaResult {
  final String category;
  final int currentSpend;
  final double wma;
  final bool isAnomaly;

  CategoryWmaResult({
    required this.category,
    required this.currentSpend,
    required this.wma,
    required this.isAnomaly,
  });
}

/// Resultado del Coeficiente de Variación para una categoría.
class CategoryCvResult {
  final String category;
  final double cv;
  final bool isImpulsive;

  CategoryCvResult({required this.category, required this.cv, required this.isImpulsive});
}

/// Modelos estadísticos del Módulo 8 (WMA y CV). Ambos requieren al
/// menos 3 ciclos completos (RQNF) y mantienen 4 decimales de precisión.
class StatisticsService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();

  static const int requiredHistoricalCycles = 3;

  /// RQNF: hay anomalía cuando el gasto del ciclo actual excede en más
  /// de un 50% el valor de la WMA.
  static const double anomalyThresholdMultiplier = 1.5;

  /// RQNF: hay patrón de gasto impulsivo cuando el CV es mayor al 40%.
  static const double impulsiveCvThreshold = 40.0;

  double _round4(double value) => double.parse(value.toStringAsFixed(4));

  /// Devuelve null si todavía no hay 3 ciclos completos.
  Future<List<CategoryWmaResult>?> computeWmaAnomalies() async {
    final currentCycle = await _cycleService.getCurrentCycle();
    final previousCycles = await _cycleService.getPreviousCycles(requiredHistoricalCycles);
    if (currentCycle == null || previousCycles.length < requiredHistoricalCycles) return null;

    final currentTotals = await _aggregateService.categoryTotalsForCycle(currentCycle);
    final cycle1Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[0]); // más reciente
    final cycle2Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[1]);
    final cycle3Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[2]); // más antiguo

    // Mayor peso a los ciclos más recientes.
    const weights = [3, 2, 1];
    const weightSum = 6;

    final categories = <String>{
      ...cycle1Totals.keys,
      ...cycle2Totals.keys,
      ...cycle3Totals.keys,
      ...currentTotals.keys,
    };

    final results = <CategoryWmaResult>[];
    for (final category in categories) {
      final g1 = cycle1Totals[category] ?? 0;
      final g2 = cycle2Totals[category] ?? 0;
      final g3 = cycle3Totals[category] ?? 0;

      final wma = _round4((weights[0] * g1 + weights[1] * g2 + weights[2] * g3) / weightSum);
      final currentSpend = currentTotals[category] ?? 0;
      final isAnomaly = wma > 0 && currentSpend > wma * anomalyThresholdMultiplier;

      results.add(CategoryWmaResult(category: category, currentSpend: currentSpend, wma: wma, isAnomaly: isAnomaly));
    }

    results.sort((a, b) => b.currentSpend.compareTo(a.currentSpend));
    return results;
  }

  /// Devuelve null si todavía no hay 3 ciclos completos.
  Future<List<CategoryCvResult>?> computeCoefficientOfVariation() async {
    final previousCycles = await _cycleService.getPreviousCycles(requiredHistoricalCycles);
    if (previousCycles.length < requiredHistoricalCycles) return null;

    final cycle1Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[0]);
    final cycle2Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[1]);
    final cycle3Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[2]);

    final categories = <String>{...cycle1Totals.keys, ...cycle2Totals.keys, ...cycle3Totals.keys};

    final results = <CategoryCvResult>[];
    for (final category in categories) {
      final values = [
        (cycle1Totals[category] ?? 0).toDouble(),
        (cycle2Totals[category] ?? 0).toDouble(),
        (cycle3Totals[category] ?? 0).toDouble(),
      ];

      final mean = values.reduce((a, b) => a + b) / values.length;
      if (mean == 0) continue;

      final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
      final stdDev = math.sqrt(variance);
      final cv = _round4((stdDev / mean) * 100);

      results.add(CategoryCvResult(category: category, cv: cv, isImpulsive: cv > impulsiveCvThreshold));
    }

    results.sort((a, b) => b.cv.compareTo(a.cv));
    return results;
  }
}
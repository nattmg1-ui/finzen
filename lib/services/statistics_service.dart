import 'dart:math' as math;
import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';

/// Resultado del WMA para una categoría: cuánto se gastó este ciclo,
/// cuál era el promedio ponderado esperado, y si eso cuenta como
/// anomalía.
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
/// menos 3 ciclos históricos COMPLETOS (RQNF) y mantienen 4 decimales
/// de precisión en los cálculos (RQNF).
class StatisticsService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();

  static const int requiredHistoricalCycles = 3;

  /// Umbral de anomalía: si el gasto actual supera 1.5x el WMA, se
  /// marca como anómalo. No viene un número exacto en el documento
  /// para este umbral específico (a diferencia del 200% que sí usa
  /// Notificaciones); 1.5x es una decisión de diseño razonable —
  /// coméntala con tu asesor si prefieren otro valor.
  static const double anomalyThresholdMultiplier = 1.5;

  /// Umbral de "gasto impulsivo": CV mayor a 50% se considera alta
  /// variabilidad. Es un valor estándar de referencia en estadística
  /// (CV > 50% ya se considera dispersión alta), pero tampoco viene
  /// fijado exactamente en el documento — mismo comentario que arriba.
  static const double impulsiveCvThreshold = 50.0;

  double _round4(double value) => double.parse(value.toStringAsFixed(4));

  /// Devuelve null si todavía no hay 3 ciclos históricos completos.
  Future<List<CategoryWmaResult>?> computeWmaAnomalies() async {
    final hasEnough = await _cycleService.hasEnoughHistoricalCycles(requiredHistoricalCycles);
    if (!hasEnough) return null;

    final currentCycle = await _cycleService.getCurrentCycle();
    final previousCycles = await _cycleService.getPreviousCycles(requiredHistoricalCycles);
    if (currentCycle == null || previousCycles.length < requiredHistoricalCycles) return null;

    final currentTotals = await _aggregateService.categoryTotalsForCycle(currentCycle);
    final cycle1Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[0]); // más reciente
    final cycle2Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[1]);
    final cycle3Totals = await _aggregateService.categoryTotalsForCycle(previousCycles[2]); // más antiguo

    // Pesos: el ciclo más reciente pesa más (RQF: "mayor peso a los
    // períodos más recientes").
    const weights = [3, 2, 1];
    const weightSum = 6; // 3+2+1

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

  /// Devuelve null si todavía no hay 3 ciclos históricos completos.
  Future<List<CategoryCvResult>?> computeCoefficientOfVariation() async {
    final hasEnough = await _cycleService.hasEnoughHistoricalCycles(requiredHistoricalCycles);
    if (!hasEnough) return null;

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
      if (mean == 0) continue; // sin historial de gasto real en esta categoría

      final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
      final stdDev = math.sqrt(variance);
      final cv = _round4((stdDev / mean) * 100);

      results.add(CategoryCvResult(category: category, cv: cv, isImpulsive: cv > impulsiveCvThreshold));
    }

    results.sort((a, b) => b.cv.compareTo(a.cv));
    return results;
  }
}
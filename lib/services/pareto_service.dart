import 'cycle_service.dart';
import 'expense_service.dart';

class ParetoCategoryResult {
  final String category;
  final int amount;
  final double percentage;
  final double cumulativePercentage;
  final bool isPriority;

  ParetoCategoryResult({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.cumulativePercentage,
    required this.isPriority,
  });
}

class ParetoResult {
  final List<ParetoCategoryResult> categories; // de mayor a menor
  final int totalCuboB;

  ParetoResult({required this.categories, required this.totalCuboB});

  List<ParetoCategoryResult> get priorityCategories => categories.where((c) => c.isPriority).toList();

  double get priorityCumulativePercentage =>
      priorityCategories.isEmpty ? 0 : priorityCategories.last.cumulativePercentage;
}

/// Análisis de Pareto sobre el Cubo B (Deseos) del ciclo actual.
class ParetoService {
  final CycleService _cycleService = CycleService();
  final ExpenseService _expenseService = ExpenseService();

  static const double _rangeMin = 75;
  static const double _rangeMax = 85;
  static const double _rangeMid = 80;

  double _round4(double value) => double.parse(value.toStringAsFixed(4));

  /// Devuelve null si no hay al menos 2 categorías del Cubo B con gasto
  /// en el ciclo actual (RQNF).
  Future<ParetoResult?> computeParetoForCurrentCycle() async {
    final currentCycle = await _cycleService.getCurrentCycle();
    if (currentCycle == null) return null;

    final expenses = await _expenseService.watchExpenses().first;
    final inCycleOpcional = expenses.where((e) => currentCycle.contains(e.date) && e.essentialType == 'Opcional');

    final byCategory = <String, int>{};
    for (final e in inCycleOpcional) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    if (byCategory.length < 2) return null;

    final totalCuboB = byCategory.values.fold(0, (sum, v) => sum + v);
    final sortedEntries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // % categoría = (gasto de la categoría / gasto total del Cubo B) × 100
    final percentages = sortedEntries.map((e) => _round4(e.value / totalCuboB * 100)).toList();

    double cumulative = 0;
    final cumulativeList = <double>[];
    for (final p in percentages) {
      cumulative = _round4(cumulative + p);
      cumulativeList.add(cumulative);
    }

    final selectedCount = _selectPriorityCount(cumulativeList);

    final categories = <ParetoCategoryResult>[];
    for (var i = 0; i < sortedEntries.length; i++) {
      categories.add(ParetoCategoryResult(
        category: sortedEntries[i].key,
        amount: sortedEntries[i].value,
        percentage: percentages[i],
        cumulativePercentage: cumulativeList[i],
        isPriority: i < selectedCount,
      ));
    }

    return ParetoResult(categories: categories, totalCuboB: totalCuboB);
  }

  /// Suma categorías de mayor a menor hasta que el acumulado quede
  /// entre 75% y 85%. Si ninguna combinación cae en ese rango, compara
  /// las dos combinaciones límite (una categoría menos, por debajo de
  /// 75%, y una más, por encima de 85%) y elige la que tenga menor
  /// diferencia absoluta respecto al 80%.
  int _selectPriorityCount(List<double> cumulativeList) {
    for (var i = 0; i < cumulativeList.length; i++) {
      if (cumulativeList[i] < _rangeMin) continue;

      if (cumulativeList[i] <= _rangeMax) return i + 1;

      if (i == 0) return 1;

      final below = cumulativeList[i - 1];
      final above = cumulativeList[i];
      final diffBelow = (below - _rangeMid).abs();
      final diffAbove = (above - _rangeMid).abs();
      return diffBelow <= diffAbove ? i : i + 1;
    }
    return cumulativeList.length;
  }
}
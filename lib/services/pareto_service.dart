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
  final List<ParetoCategoryResult> categories; // ordenadas de mayor a menor
  final int totalCuboB;

  ParetoResult({required this.categories, required this.totalCuboB});

  List<ParetoCategoryResult> get priorityCategories => categories.where((c) => c.isPriority).toList();

  double get priorityCumulativePercentage =>
      priorityCategories.isEmpty ? 0 : priorityCategories.last.cumulativePercentage;
}

/// Análisis de Pareto sobre el Cubo B (gasto Opcional/Deseos) del
/// ciclo actual: qué categorías concentran la mayor parte del gasto
/// discrecional.
class ParetoService {
  final CycleService _cycleService = CycleService();
  final ExpenseService _expenseService = ExpenseService();

  double _round4(double value) => double.parse(value.toStringAsFixed(4));

  /// Devuelve null si no hay al menos 2 categorías de gasto Opcional
  /// con movimiento en el ciclo actual (RQNF).
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

  /// Busca cuántas categorías (de mayor a menor) hacen falta para que
  /// el % acumulado caiga entre 75% y 85% (RQNF). Si un salto se pasa
  /// de 85%, elige el conteo más cercano al rango entre incluir una
  /// categoría menos (por debajo de 75%) o una más (por encima de 85%).
  int _selectPriorityCount(List<double> cumulativeList) {
    for (var i = 0; i < cumulativeList.length; i++) {
      if (cumulativeList[i] >= 75) {
        if (cumulativeList[i] <= 85) {
          return i + 1;
        }
        if (i == 0) return 1;
        final distBelow = 75 - cumulativeList[i - 1];
        final distAbove = cumulativeList[i] - 85;
        return distBelow <= distAbove ? i : i + 1;
      }
    }
    // Ni sumando todas las categorías se llega a 75% (gasto muy
    // repartido): se incluyen todas las que hay.
    return cumulativeList.length;
  }
}
import '../models/expense_model.dart';
import 'cycle_service.dart';
import 'cycle_aggregate_service.dart';
import 'expense_service.dart';
import 'firestore_service.dart';

class ExponentialSmoothingResult {
  final double projection;
  final bool isCalibrating;
  final int recordsSoFar;
  final int recordsNeeded;

  ExponentialSmoothingResult({
    required this.projection,
    required this.isCalibrating,
    required this.recordsSoFar,
    required this.recordsNeeded,
  });
}

/// Proyección de gasto esperado al cierre del ciclo actual, usando el
/// modelo de Suavizamiento Exponencial: Sₜ = 0.3×Xₜ + 0.7×Sₜ₋₁.
class ExponentialSmoothingService {
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();
  final ExpenseService _expenseService = ExpenseService();
  final FirestoreService _firestoreService = FirestoreService();

  /// RQNF: factor de suavización fijo para todo el sistema.
  static const double alpha = 0.3;

  /// RQNF: el modelo solo se aplica después de 10 gastos registrados.
  static const int calibrationMinRecords = 10;

  double _round4(double value) => double.parse(value.toStringAsFixed(4));

  Future<ExponentialSmoothingResult> computeProjection() async {
    final allExpenses = await _expenseService.watchExpenses().first;

    // RQNF: durante la calibración (menos de 10 gastos), se usa una
    // proyección inicial basada en el diagnóstico, no el modelo
    // recursivo completo todavía.
    if (allExpenses.length < calibrationMinRecords) {
      final initial = await _calibrationProjection(allExpenses);
      return ExponentialSmoothingResult(
        projection: initial,
        isCalibrating: true,
        recordsSoFar: allExpenses.length,
        recordsNeeded: calibrationMinRecords,
      );
    }

    final currentCycle = await _cycleService.getCurrentCycle();
    if (currentCycle == null) {
      return ExponentialSmoothingResult(
        projection: 0,
        isCalibrating: true,
        recordsSoFar: allExpenses.length,
        recordsNeeded: calibrationMinRecords,
      );
    }

    // Todos los ciclos cerrados, del más antiguo al más reciente, para
    // encadenar la recursión desde el principio.
    final allPreviousCycles = await _cycleService.getAllPreviousCycles();
    final oldestFirst = allPreviousCycles.reversed.toList();

    double s = await _calibrationProjection(allExpenses); // semilla S₀
    for (final cycle in oldestFirst) {
      final aggregate = await _aggregateService.aggregateForCycle(cycle);
      final x = aggregate.totalSpent.toDouble();
      s = _round4(alpha * x + (1 - alpha) * s);
    }

    // Ciclo actual (todavía abierto): usa lo gastado hasta hoy.
    final currentAggregate = await _aggregateService.aggregateForCycle(currentCycle);
    final xCurrent = currentAggregate.totalSpent.toDouble();
    final projection = _round4(alpha * xCurrent + (1 - alpha) * s);

    return ExponentialSmoothingResult(
      projection: projection,
      isCalibrating: false,
      recordsSoFar: allExpenses.length,
      recordsNeeded: calibrationMinRecords,
    );
  }

  /// Proyección inicial (S₀) durante calibración: promedio entre lo
  /// que el usuario declaró en el diagnóstico como gastos básicos
  /// mensuales, y lo que realmente ha gastado hasta ahora.
  Future<double> _calibrationProjection(List<ExpenseModel> expenses) async {
    final user = await _firestoreService.fetchCurrentUserProfile();
    final diagnosisExpenses = (user?.diagnosis?['monthlyBasicExpenses'] as num?)?.toDouble();

    if (expenses.isEmpty) {
      return diagnosisExpenses ?? 0;
    }

    final actualTotal = expenses.fold<int>(0, (sum, e) => sum + e.amount).toDouble();
    if (diagnosisExpenses == null) return actualTotal;

    return _round4((diagnosisExpenses + actualTotal) / 2);
  }
}
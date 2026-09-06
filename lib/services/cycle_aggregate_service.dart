import '../models/cycle_info.dart';
import 'expense_service.dart';
import 'goal_contribution_service.dart';

/// Resultado de clasificar el gasto/ahorro de UN ciclo en los 3
/// cubos que define el Módulo 8.
class CycleAggregate {
  final int cuboA; // Vital (necesidades)
  final int cuboB; // Opcional (deseos)
  final int cuboC; // Futuro (aportado a metas de ahorro)

  CycleAggregate({required this.cuboA, required this.cuboB, required this.cuboC});

  int get total => cuboA + cuboB + cuboC;

  /// Total gastado en el sentido tradicional (sin contar lo ahorrado),
  /// útil para varios de los modelos estadísticos que vienen después.
  int get totalSpent => cuboA + cuboB;
}

/// Combina Gastos (ya clasificados Vital/Opcional desde el Módulo 4)
/// y el historial de aportes a metas, filtrado por las fechas de un
/// ciclo específico.
class CycleAggregateService {
  final ExpenseService _expenseService = ExpenseService();
  final GoalContributionService _contributionService = GoalContributionService();

  Future<CycleAggregate> aggregateForCycle(CycleInfo cycle) async {
    final expenses = await _expenseService.watchExpenses().first;
    final contributions = await _contributionService.watchAll().first;

    final expensesInCycle = expenses.where((e) => cycle.contains(e.date));
    final cuboA = expensesInCycle.where((e) => e.essentialType == 'Vital').fold(0, (sum, e) => sum + e.amount);
    final cuboB = expensesInCycle.where((e) => e.essentialType == 'Opcional').fold(0, (sum, e) => sum + e.amount);

    final contributionsInCycle = contributions.where((c) => cycle.contains(c.createdAt));
    final cuboC = contributionsInCycle.fold(0, (sum, c) => sum + c.amount);

    return CycleAggregate(cuboA: cuboA, cuboB: cuboB, cuboC: cuboC);
  }

  /// Por categoría de gasto dentro de un ciclo (lo van a usar WMA y Pareto).
  Future<Map<String, int>> categoryTotalsForCycle(CycleInfo cycle) async {
    final expenses = await _expenseService.watchExpenses().first;
    final map = <String, int>{};
    for (final e in expenses.where((e) => cycle.contains(e.date))) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}
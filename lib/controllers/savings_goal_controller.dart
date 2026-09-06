import 'package:flutter/material.dart';
import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';

class SavingsGoalController extends ChangeNotifier {
  final SavingsGoalService _service = SavingsGoalService();
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();

  static const List<String> priorities = ['Alta', 'Media', 'Baja'];
  static const String pausedMessage = 'Pausada: tus gastos básicos están en riesgo';
  static const int maxYearsAhead = 4;

  List<SavingsGoalModel> goals = [];
  bool isLoading = true;
  String? errorMessage;

  Set<String> pausedGoalIds = {};
  String? adjustmentMessage;

  int _totalIncome = 0;
  int _totalVitalExpenses = 0;

  SavingsGoalController() {
    _service.watchGoals().listen(
      (data) {
        goals = data;
        isLoading = false;
        _recomputePaused();
      },
      onError: (_) {
        errorMessage = 'No se pudieron cargar tus metas.';
        isLoading = false;
        notifyListeners();
      },
    );

    _incomeService.watchIncomes().listen((incomes) {
      _totalIncome = incomes.fold(0, (sum, i) => sum + i.amount);
      _recomputePaused();
    });

    _expenseService.watchExpenses().listen((expenses) {
      _totalVitalExpenses = expenses.where((e) => e.essentialType == 'Vital').fold(0, (sum, e) => sum + e.amount);
      _recomputePaused();
    });
  }

  int _priorityRank(String priority) {
    switch (priority) {
      case 'Alta':
        return 0;
      case 'Media':
        return 1;
      default:
        return 2;
    }
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  void _recomputePaused() {
    double remainingCapacity = (_totalIncome - _totalVitalExpenses).toDouble();
    if (remainingCapacity < 0) remainingCapacity = 0;

    final activeGoalsSorted = goals.where((g) => !g.completed).toList()
      ..sort((a, b) => _priorityRank(a.priority).compareTo(_priorityRank(b.priority)));

    final today = DateTime.now();
    final newPaused = <String>{};

    for (final goal in activeGoalsSorted) {
      final remainingTarget = goal.targetAmount - goal.currentAmount;
      if (remainingTarget <= 0) continue;

      final monthsRemaining = _monthsBetween(today, goal.deadline).clamp(1, 999);
      final requiredQuota = remainingTarget / monthsRemaining;

      if (requiredQuota <= remainingCapacity) {
        remainingCapacity -= requiredQuota;
      } else {
        newPaused.add(goal.id);
      }
    }

    pausedGoalIds = newPaused;
    notifyListeners();
  }

  bool isPaused(String goalId) => pausedGoalIds.contains(goalId);

  List<SavingsGoalModel> activeGoalsExcept(String excludeId) {
    return goals.where((g) => !g.completed && g.id != excludeId).toList();
  }

  DateTime maxAllowedDeadline() {
    final today = DateTime.now();
    return DateTime(today.year + maxYearsAhead, today.month, today.day);
  }

  /// Calcula la fecha límite final a usar. Devuelve null cuando la
  /// meta NO es viable dentro del horizonte máximo de 4 años (ni con
  /// la fecha pedida, ni con la fecha mínima que haría la cuota
  /// mensual viable según el 20% del ingreso) — en ese caso la meta
  /// se rechaza por completo, no se guarda con una fecha fuera de rango.
  Future<DateTime?> _resolveViableDeadline({
    required int targetAmount,
    required int currentAmount,
    required DateTime requestedDeadline,
  }) async {
    final maxDeadline = maxAllowedDeadline();
    final remaining = targetAmount - currentAmount;

    final incomeList = await _incomeService.watchIncomes().first;
    final totalIncome = incomeList.fold<int>(0, (sum, i) => sum + i.amount);

    // Sin ingreso registrado o meta ya cubierta: solo importa el
    // horizonte máximo de años.
    if (totalIncome <= 0 || remaining <= 0) {
      if (requestedDeadline.isAfter(maxDeadline)) return null;
      return requestedDeadline;
    }

    final maxMonthlyQuota = totalIncome * 0.20;
    if (maxMonthlyQuota <= 0) {
      if (requestedDeadline.isAfter(maxDeadline)) return null;
      return requestedDeadline;
    }

    final today = DateTime.now();
    final requestedMonths = _monthsBetween(today, requestedDeadline).clamp(1, 999);
    final requestedQuota = remaining / requestedMonths;

    if (requestedQuota <= maxMonthlyQuota) {
      // La fecha pedida ya es viable en cuota, pero igual debe
      // respetar el máximo de años.
      if (requestedDeadline.isAfter(maxDeadline)) return null;
      return requestedDeadline;
    }

    final minMonthsNeeded = (remaining / maxMonthlyQuota).ceil();
    final adjustedDeadline = DateTime(today.year, today.month + minMonthsNeeded, today.day);

    if (adjustedDeadline.isAfter(maxDeadline)) {
      // Ni siquiera la fecha mínima viable cabe en 4 años: la meta
      // no es viable, punto — no se guarda con una fecha fuera de rango.
      return null;
    }

    adjustmentMessage = 'Tu fecha límite no era viable con tu ingreso registrado '
        '(requería ahorrar más del 20% mensual). El sistema la ajustó '
        'automáticamente al ${adjustedDeadline.day}/${adjustedDeadline.month}/${adjustedDeadline.year}.';

    return adjustedDeadline;
  }

  Future<bool> addGoal({
    required String name,
    required String targetAmountText,
    required String priority,
    required DateTime deadline,
  }) async {
    if (name.trim().isEmpty) {
      errorMessage = 'El nombre de la meta es obligatorio';
      notifyListeners();
      return false;
    }
    final targetAmount = int.tryParse(targetAmountText.trim());
    if (targetAmount == null || targetAmount <= 0) {
      errorMessage = 'Ingresa un monto objetivo numérico mayor a cero';
      notifyListeners();
      return false;
    }
    if (!priorities.contains(priority)) {
      errorMessage = 'Selecciona una prioridad válida';
      notifyListeners();
      return false;
    }
    final today = DateTime.now();
    final todayAtMidnight = DateTime(today.year, today.month, today.day);
    if (!deadline.isAfter(todayAtMidnight)) {
      errorMessage = 'La fecha límite debe ser posterior a hoy';
      notifyListeners();
      return false;
    }

    try {
      adjustmentMessage = null;
      final finalDeadline = await _resolveViableDeadline(
        targetAmount: targetAmount,
        currentAmount: 0,
        requestedDeadline: deadline,
      );

      if (finalDeadline == null) {
        errorMessage = 'Esta meta no es viable, no se puede crear: incluso ahorrando el máximo recomendado '
            '(20% de tu ingreso) necesitarías más de $maxYearsAhead años para cumplirla. '
            'Reduce el monto objetivo o registra más ingresos.';
        notifyListeners();
        return false;
      }

      await _service.addGoal(name: name.trim(), targetAmount: targetAmount, priority: priority, deadline: finalDeadline);
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'No se pudo guardar la meta. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editGoal({
    required String goalId,
    required String name,
    required String targetAmountText,
    required int currentAmount,
    required String priority,
    required DateTime deadline,
  }) async {
    if (name.trim().isEmpty) {
      errorMessage = 'El nombre de la meta es obligatorio';
      notifyListeners();
      return false;
    }
    final targetAmount = int.tryParse(targetAmountText.trim());
    if (targetAmount == null || targetAmount <= 0) {
      errorMessage = 'Ingresa un monto objetivo numérico mayor a cero';
      notifyListeners();
      return false;
    }
    if (!priorities.contains(priority)) {
      errorMessage = 'Selecciona una prioridad válida';
      notifyListeners();
      return false;
    }
    final today = DateTime.now();
    final todayAtMidnight = DateTime(today.year, today.month, today.day);
    if (!deadline.isAfter(todayAtMidnight)) {
      errorMessage = 'La nueva fecha límite debe ser posterior a hoy';
      notifyListeners();
      return false;
    }

    try {
      adjustmentMessage = null;
      final finalDeadline = await _resolveViableDeadline(
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        requestedDeadline: deadline,
      );

      if (finalDeadline == null) {
        errorMessage = 'Esta meta no es viable, no se puede guardar así: incluso ahorrando el máximo recomendado '
            '(20% de tu ingreso) necesitarías más de $maxYearsAhead años para cumplirla. '
            'Reduce el monto objetivo o elige una fecha distinta.';
        notifyListeners();
        return false;
      }

      await _service.updateGoal(goalId: goalId, name: name.trim(), targetAmount: targetAmount, priority: priority, deadline: finalDeadline);
      errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'No se pudo actualizar la meta. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> recalibrateDeadline(SavingsGoalModel goal) async {
    try {
      adjustmentMessage = null;
      final suggested = await _resolveViableDeadline(
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        requestedDeadline: goal.deadline,
      );

      if (suggested == null) {
        errorMessage = 'Esta meta ya no es viable con tu situación actual, ni ampliándola hasta el máximo de '
            '$maxYearsAhead años. Considera reducir el monto objetivo.';
        notifyListeners();
        return false;
      }

      if (suggested.year == goal.deadline.year && suggested.month == goal.deadline.month && suggested.day == goal.deadline.day) {
        adjustmentMessage = 'Tu fecha límite actual sigue siendo viable con tu situación de hoy. No hubo cambios.';
        notifyListeners();
        return true;
      }

      await _service.updateGoal(
        goalId: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        priority: goal.priority,
        deadline: suggested,
      );
      adjustmentMessage = 'Se actualizó la fecha límite al ${suggested.day}/${suggested.month}/${suggested.year} '
          'según tu ingreso y gastos actuales.';
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'No se pudo recalcular la fecha. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<({bool success, bool justCompleted})> addFunds(SavingsGoalModel goal, String amountText) async {
    if (isPaused(goal.id)) {
      errorMessage = 'Esta meta está pausada porque tus gastos básicos están en riesgo. No puedes aportar mientras tanto.';
      notifyListeners();
      return (success: false, justCompleted: false);
    }

    final amount = int.tryParse(amountText.trim());
    if (amount == null || amount <= 0) {
      errorMessage = 'Ingresa un monto numérico válido mayor a cero';
      notifyListeners();
      return (success: false, justCompleted: false);
    }
    final willComplete = !goal.completed && (goal.currentAmount + amount) >= goal.targetAmount;
    try {
      await _service.addFunds(
        goalId: goal.id,
        currentAmount: goal.currentAmount,
        targetAmount: goal.targetAmount,
        amountToAdd: amount,
      );
      return (success: true, justCompleted: willComplete);
    } catch (_) {
      errorMessage = 'No se pudo registrar el aporte. Intenta de nuevo.';
      notifyListeners();
      return (success: false, justCompleted: false);
    }
  }

  Future<bool> redirectCompletedGoalFunds(SavingsGoalModel goal, {String? destinationGoalId}) async {
    if (destinationGoalId == null) return true;
    try {
      final destination = goals.firstWhere((g) => g.id == destinationGoalId);
      await _service.addFunds(
        goalId: destination.id,
        currentAmount: destination.currentAmount,
        targetAmount: destination.targetAmount,
        amountToAdd: goal.currentAmount,
      );
      return true;
    } catch (_) {
      errorMessage = 'No se pudo redirigir el saldo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGoal(SavingsGoalModel goal, {String? destinationGoalId}) async {
    try {
      if (destinationGoalId != null && goal.currentAmount > 0) {
        final destination = goals.firstWhere((g) => g.id == destinationGoalId);
        await _service.addFunds(
          goalId: destination.id,
          currentAmount: destination.currentAmount,
          targetAmount: destination.targetAmount,
          amountToAdd: goal.currentAmount,
        );
      }
      await _service.deleteGoal(goal.id);
      return true;
    } catch (_) {
      errorMessage = 'No se pudo eliminar la meta. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }
}
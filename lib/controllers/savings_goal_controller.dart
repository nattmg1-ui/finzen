import 'package:flutter/material.dart';
import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/monthly_budget_service.dart';

class SavingsGoalController extends ChangeNotifier {
  final SavingsGoalService _service = SavingsGoalService();
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final MonthlyBudgetService _budgetService = MonthlyBudgetService();

  static const List<String> priorities = ['Alta', 'Media', 'Baja'];
  static const List<String> types = ['Vital', 'Opcional'];
  static const String pausedMessage = 'Pausada: tus gastos básicos están en riesgo';
  static const int maxYearsAhead = 4;

  /// RQNF: la cuota mensual no debe exceder el 20% del ingreso mensual.
  static const double maxQuotaRatio = 0.20;

  List<SavingsGoalModel> goals = [];
  bool isLoading = true;
  String? errorMessage;
  String? adjustmentMessage;

  bool _isEvaluating = false;

  SavingsGoalController() {
    _service.watchGoals().listen(
      (data) {
        goals = data;
        isLoading = false;
        notifyListeners();
        _evaluatePauseReactivation();
      },
      onError: (_) {
        errorMessage = 'No se pudieron cargar tus metas.';
        isLoading = false;
        notifyListeners();
      },
    );

    // Cualquier cambio en ingresos o gastos vuelve a evaluar el pausado.
    _incomeService.watchIncomes().listen((_) => _evaluatePauseReactivation());
    _expenseService.watchExpenses().listen((_) => _evaluatePauseReactivation());
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  double _quotaFor(SavingsGoalModel g) {
    final remaining = g.targetAmount - g.currentAmount;
    if (remaining <= 0) return 0;
    final months = _monthsBetween(DateTime.now(), g.deadline).clamp(1, 999);
    return remaining / months;
  }

  /// Orden de pausado: ascendente de prioridad (Baja, Media, Alta). En
  /// empate, la de fecha límite más lejana se pausa primero.
  int _pauseOrderComparator(SavingsGoalModel a, SavingsGoalModel b) {
    const rank = {'Baja': 0, 'Media': 1, 'Alta': 2};
    final rankA = rank[a.priority] ?? 0;
    final rankB = rank[b.priority] ?? 0;
    if (rankA != rankB) return rankA.compareTo(rankB);
    return b.deadline.compareTo(a.deadline);
  }

  /// Capacidad de ahorro = ingreso mensual - gastos básicos mensuales.
  ///
  /// Pausar: si las cuotas de las metas activas superan la capacidad,
  /// pausa primero las Opcionales y, si no alcanza, las Vitales.
  ///
  /// Reactivar: en orden inverso al que se pausaron, solo si la
  /// capacidad alcanza para cubrir la cuota de la meta a reactivar.
  Future<void> _evaluatePauseReactivation() async {
    if (_isEvaluating) return;
    _isEvaluating = true;
    try {
      final monthlyIncome = await _budgetService.monthlyIncome();

      // Sin ingreso registrado en el ciclo no hay base para decidir;
      // se conserva el estado actual de las metas.
      if (monthlyIncome <= 0) return;

      final monthlyBasic = await _budgetService.monthlyBasicExpenses();
      double capacity = (monthlyIncome - monthlyBasic).toDouble();
      if (capacity < 0) capacity = 0;

      final relevantGoals = goals.where((g) => !g.completed).toList();
      final activeGoals = relevantGoals.where((g) => !g.paused).toList();
      final pausedNewestFirst = relevantGoals.where((g) => g.paused).toList()
        ..sort((a, b) => (b.pausedAt ?? DateTime(0)).compareTo(a.pausedAt ?? DateTime(0)));

      final neededForActive = activeGoals.fold<double>(0, (sum, g) => sum + _quotaFor(g));

      if (neededForActive > capacity) {
        final opcionalCandidates = activeGoals.where((g) => g.type == 'Opcional').toList()..sort(_pauseOrderComparator);
        final vitalCandidates = activeGoals.where((g) => g.type == 'Vital').toList()..sort(_pauseOrderComparator);

        var stillNeeded = neededForActive;
        for (final candidate in [...opcionalCandidates, ...vitalCandidates]) {
          if (stillNeeded <= capacity) break;
          stillNeeded -= _quotaFor(candidate);
          await _service.setPaused(candidate.id, paused: true);
        }
      } else if (pausedNewestFirst.isNotEmpty) {
        var freeCapacity = capacity - neededForActive;
        for (final g in pausedNewestFirst) {
          final quota = _quotaFor(g);
          if (quota <= freeCapacity) {
            await _service.setPaused(g.id, paused: false);
            freeCapacity -= quota;
          } else {
            break;
          }
        }
      }
    } finally {
      _isEvaluating = false;
    }
  }

  bool isPaused(String goalId) {
    try {
      return goals.firstWhere((g) => g.id == goalId).paused;
    } catch (_) {
      return false;
    }
  }

  List<SavingsGoalModel> activeGoalsExcept(String excludeId) {
    return goals.where((g) => !g.completed && g.id != excludeId).toList();
  }

  DateTime maxAllowedDeadline() {
    final today = DateTime.now();
    return DateTime(today.year + maxYearsAhead, today.month, today.day);
  }

  /// Devuelve la fecha límite final. Si la cuota mensual supera el 20%
  /// del ingreso mensual, recalibra la fecha. Devuelve null si ni con
  /// el máximo de 4 años la meta es viable.
  Future<DateTime?> _resolveViableDeadline({
    required int targetAmount,
    required int currentAmount,
    required DateTime requestedDeadline,
  }) async {
    final maxDeadline = maxAllowedDeadline();
    final remaining = targetAmount - currentAmount;
    final monthlyIncome = await _budgetService.monthlyIncome();

    if (monthlyIncome <= 0 || remaining <= 0) {
      if (requestedDeadline.isAfter(maxDeadline)) return null;
      return requestedDeadline;
    }

    final maxMonthlyQuota = monthlyIncome * maxQuotaRatio;

    final today = DateTime.now();
    final requestedMonths = _monthsBetween(today, requestedDeadline).clamp(1, 999);
    final requestedQuota = remaining / requestedMonths;

    if (requestedQuota <= maxMonthlyQuota) {
      if (requestedDeadline.isAfter(maxDeadline)) return null;
      return requestedDeadline;
    }

    final minMonthsNeeded = (remaining / maxMonthlyQuota).ceil();
    final adjustedDeadline = DateTime(today.year, today.month + minMonthsNeeded, today.day);

    if (adjustedDeadline.isAfter(maxDeadline)) return null;

    adjustmentMessage = 'Tu fecha límite no era viable con tu ingreso mensual '
        '(requería ahorrar más del 20% al mes). El sistema la ajustó '
        'automáticamente al ${adjustedDeadline.day}/${adjustedDeadline.month}/${adjustedDeadline.year}.';

    return adjustedDeadline;
  }

  String? _validateCommon({
    required String name,
    required int? targetAmount,
    required String priority,
    required String type,
    required DateTime deadline,
  }) {
    if (name.trim().isEmpty) return 'El nombre de la meta es obligatorio.';
    if (targetAmount == null || targetAmount <= 0) return 'Ingresa un monto objetivo numérico mayor a cero.';
    if (!priorities.contains(priority)) return 'Selecciona una prioridad válida.';
    if (!types.contains(type)) return 'Selecciona un tipo válido (Vital u Opcional).';
    final today = DateTime.now();
    final todayAtMidnight = DateTime(today.year, today.month, today.day);
    if (!deadline.isAfter(todayAtMidnight)) return 'La fecha límite debe ser posterior a hoy.';
    return null;
  }

  Future<bool> addGoal({
    required String name,
    required String targetAmountText,
    required String priority,
    required String type,
    required DateTime deadline,
  }) async {
    final targetAmount = int.tryParse(targetAmountText.trim());
    final validationError = _validateCommon(
      name: name,
      targetAmount: targetAmount,
      priority: priority,
      type: type,
      deadline: deadline,
    );
    if (validationError != null) {
      errorMessage = validationError;
      notifyListeners();
      return false;
    }

    try {
      adjustmentMessage = null;
      final finalDeadline = await _resolveViableDeadline(
        targetAmount: targetAmount!,
        currentAmount: 0,
        requestedDeadline: deadline,
      );

      if (finalDeadline == null) {
        errorMessage = 'Esta meta no es viable, no se puede crear: incluso ahorrando el máximo recomendado '
            '(20% de tu ingreso mensual) necesitarías más de $maxYearsAhead años para cumplirla. '
            'Reduce el monto objetivo o registra más ingresos.';
        notifyListeners();
        return false;
      }

      await _service.addGoal(name: name.trim(), targetAmount: targetAmount, priority: priority, type: type, deadline: finalDeadline);
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
    required String type,
    required DateTime deadline,
  }) async {
    final targetAmount = int.tryParse(targetAmountText.trim());
    final validationError = _validateCommon(
      name: name,
      targetAmount: targetAmount,
      priority: priority,
      type: type,
      deadline: deadline,
    );
    if (validationError != null) {
      errorMessage = validationError;
      notifyListeners();
      return false;
    }

    try {
      adjustmentMessage = null;
      final finalDeadline = await _resolveViableDeadline(
        targetAmount: targetAmount!,
        currentAmount: currentAmount,
        requestedDeadline: deadline,
      );

      if (finalDeadline == null) {
        errorMessage = 'Esta meta no es viable, no se puede guardar así: incluso ahorrando el máximo recomendado '
            '(20% de tu ingreso mensual) necesitarías más de $maxYearsAhead años para cumplirla. '
            'Reduce el monto objetivo o elige una fecha distinta.';
        notifyListeners();
        return false;
      }

      await _service.updateGoal(
        goalId: goalId,
        name: name.trim(),
        targetAmount: targetAmount,
        priority: priority,
        type: type,
        deadline: finalDeadline,
      );
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

      final sameDate = suggested.year == goal.deadline.year &&
          suggested.month == goal.deadline.month &&
          suggested.day == goal.deadline.day;
      if (sameDate) {
        adjustmentMessage = 'Tu fecha límite actual sigue siendo viable con tu situación de hoy. No hubo cambios.';
        notifyListeners();
        return true;
      }

      await _service.updateGoal(
        goalId: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        priority: goal.priority,
        type: goal.type,
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

  /// RQNF: no se permiten aportaciones manuales a una meta pausada.
  Future<({bool success, bool justCompleted})> addFunds(SavingsGoalModel goal, String amountText) async {
    if (goal.paused) {
      errorMessage = 'Esta meta está pausada. No puedes aportar mientras tanto.';
      notifyListeners();
      return (success: false, justCompleted: false);
    }

    final amount = int.tryParse(amountText.trim());
    if (amount == null || amount <= 0) {
      errorMessage = 'Ingresa un monto numérico válido mayor a cero.';
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
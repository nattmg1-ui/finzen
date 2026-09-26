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
  static const List<String> types = ['Vital', 'Opcional'];
  static const String pausedMessage = 'Pausada: tus gastos básicos están en riesgo';
  static const int maxYearsAhead = 4;

  List<SavingsGoalModel> goals = [];
  bool isLoading = true;
  String? errorMessage;
  String? adjustmentMessage;

  int _totalIncome = 0;
  int _totalVitalExpenses = 0;
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

    _incomeService.watchIncomes().listen((incomes) {
      _totalIncome = incomes.fold(0, (sum, i) => sum + i.amount);
      _evaluatePauseReactivation();
    });

    _expenseService.watchExpenses().listen((expenses) {
      _totalVitalExpenses = expenses.where((e) => e.essentialType == 'Vital').fold(0, (sum, e) => sum + e.amount);
      _evaluatePauseReactivation();
    });
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

  /// Orden de pausado: ascendente de prioridad (Baja primero, luego
  /// Media, luego Alta — pausamos lo menos importante primero). En
  /// caso de empate, la de fecha límite MÁS LEJANA se pausa primero.
  int _pauseOrderComparator(SavingsGoalModel a, SavingsGoalModel b) {
    const rank = {'Baja': 0, 'Media': 1, 'Alta': 2};
    final rankA = rank[a.priority] ?? 0;
    final rankB = rank[b.priority] ?? 0;
    if (rankA != rankB) return rankA.compareTo(rankB);
    return b.deadline.compareTo(a.deadline);
  }

  /// El "motor" de pausado/reactivación. Se ejecuta cada vez que
  /// cambian los ingresos, gastos, o las metas mismas.
  ///
  /// Pausar: primero agota las metas Opcionales activas (una por una,
  /// en orden ascendente de prioridad, empate = fecha más lejana). Si
  /// ya no quedan Opcionales activas que pausar y la cuota restante
  /// sigue en riesgo, empieza a pausar Vitales con el mismo orden.
  ///
  /// Reactivar: en orden INVERSO al que se pausaron (la más reciente
  /// en pausarse se reactiva primero), solo si el ingreso alcanza
  /// para cubrir gastos básicos + esa cuota + las ya activas.
  Future<void> _evaluatePauseReactivation() async {
    if (_isEvaluating) return;
    _isEvaluating = true;
    try {
      double capacity = (_totalIncome - _totalVitalExpenses).toDouble();
      if (capacity < 0) capacity = 0;

      final relevantGoals = goals.where((g) => !g.completed).toList();
      final activeGoals = relevantGoals.where((g) => !g.paused).toList();
      final pausedGoalsNewestFirst = relevantGoals.where((g) => g.paused).toList()
        ..sort((a, b) => (b.pausedAt ?? DateTime(0)).compareTo(a.pausedAt ?? DateTime(0)));

      final neededForActive = activeGoals.fold<double>(0, (sum, g) => sum + _quotaFor(g));

      if (neededForActive > capacity) {
        // Hay que pausar: Opcionales activas primero, luego Vitales.
        final opcionalCandidates = activeGoals.where((g) => g.type == 'Opcional').toList()..sort(_pauseOrderComparator);
        final vitalCandidates = activeGoals.where((g) => g.type == 'Vital').toList()..sort(_pauseOrderComparator);

        var stillNeeded = neededForActive;
        for (final candidate in [...opcionalCandidates, ...vitalCandidates]) {
          if (stillNeeded <= capacity) break;
          stillNeeded -= _quotaFor(candidate);
          await _service.setPaused(candidate.id, paused: true);
        }
      } else if (pausedGoalsNewestFirst.isNotEmpty) {
        // Hay margen: intenta reactivar empezando por la más reciente
        // en haberse pausado.
        var freeCapacity = capacity - neededForActive;
        for (final g in pausedGoalsNewestFirst) {
          final quota = _quotaFor(g);
          if (quota <= freeCapacity) {
            await _service.setPaused(g.id, paused: false);
            freeCapacity -= quota;
          } else {
            break; // mantiene el orden: si esta no cabe, no probamos las siguientes
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

  Future<DateTime?> _resolveViableDeadline({
    required int targetAmount,
    required int currentAmount,
    required DateTime requestedDeadline,
  }) async {
    final maxDeadline = maxAllowedDeadline();
    final remaining = targetAmount - currentAmount;

    final incomeList = await _incomeService.watchIncomes().first;
    final totalIncome = incomeList.fold<int>(0, (sum, i) => sum + i.amount);

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
      if (requestedDeadline.isAfter(maxDeadline)) return null;
      return requestedDeadline;
    }

    final minMonthsNeeded = (remaining / maxMonthlyQuota).ceil();
    final adjustedDeadline = DateTime(today.year, today.month + minMonthsNeeded, today.day);

    if (adjustedDeadline.isAfter(maxDeadline)) {
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
    required String type,
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
    if (!types.contains(type)) {
      errorMessage = 'Selecciona un tipo válido (Vital u Opcional)';
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
    if (!types.contains(type)) {
      errorMessage = 'Selecciona un tipo válido (Vital u Opcional)';
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

  /// RQNF: no se permiten aportaciones manuales mientras la meta esté pausada.
  Future<({bool success, bool justCompleted})> addFunds(SavingsGoalModel goal, String amountText) async {
    if (goal.paused) {
      errorMessage = 'Esta meta está pausada. No puedes aportar mientras tanto.';
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
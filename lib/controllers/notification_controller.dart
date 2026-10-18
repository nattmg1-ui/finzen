import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/expense_model.dart';
import '../services/notification_service.dart';
import '../services/expense_service.dart';
import '../services/savings_goal_service.dart';
import '../services/firestore_service.dart';
import '../services/local_notification_service.dart';
import '../services/financial_mode_service.dart';
import '../services/cycle_service.dart';
import '../services/cycle_aggregate_service.dart';

/// Motor de notificaciones del Módulo 6 (Anexo B). Se ejecuta al abrir
/// el Dashboard. Respeta: horario silencioso, máximo 2 por día,
/// preferencias del usuario y el contexto del ciclo actual.
class NotificationController extends ChangeNotifier {
  final NotificationService _notifService = NotificationService();
  final LocalNotificationService _localNotifService = LocalNotificationService();
  final ExpenseService _expenseService = ExpenseService();
  final SavingsGoalService _goalService = SavingsGoalService();
  final FirestoreService _firestoreService = FirestoreService();
  final FinancialModeService _financialModeService = FinancialModeService();
  final CycleService _cycleService = CycleService();
  final CycleAggregateService _aggregateService = CycleAggregateService();

  static const int maxPerDay = 2;
  static const int quietHourStart = 23; // 11:00 pm
  static const int quietHourEnd = 8; // 8:00 am

  List<NotificationModel> notifications = [];
  bool isLoading = true;

  NotificationController() {
    _notifService.watchNotifications().listen((data) {
      notifications = data;
      isLoading = false;
      notifyListeners();
    });
  }

  int get unreadCount => notifications.where((n) => !n.read).length;

  bool get _isQuietHours {
    final hour = DateTime.now().hour;
    return hour >= quietHourStart || hour < quietHourEnd;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Guarda la notificación en Firestore y muestra el banner del sistema.
  Future<void> _emit({
    required String type,
    required String title,
    required String message,
    required String dedupKey,
  }) async {
    await _notifService.add(type: type, title: title, message: message, dedupKey: dedupKey);
    await _localNotifService.show(title: title, body: message);
  }

  Future<void> evaluateAndGenerate() async {
    if (_isQuietHours) return;

    var remaining = maxPerDay - await _notifService.countCreatedToday();
    if (remaining <= 0) return;

    final user = await _firestoreService.fetchCurrentUserProfile();
    final expenses = await _expenseService.watchExpenses().first;
    final goals = await _goalService.watchGoals().first;

    final expenseAlertsOn = user?.notifyExpenseAlerts ?? true;
    final goalAlertsOn = user?.notifyGoalAlerts ?? true;

    // Ingreso y gasto del CICLO ACTUAL (no del historial completo).
    final currentCycle = await _cycleService.getCurrentCycle();
    var cycleIncome = 0;
    var cycleExpenses = 0;
    if (currentCycle != null) {
      cycleIncome = await _cycleService.incomeInCycle(currentCycle);
      final aggregate = await _aggregateService.aggregateForCycle(currentCycle);
      cycleExpenses = aggregate.totalSpent;
    }

    // Regla 1: margen del ciclo menor al 10% del ingreso.
    if (remaining > 0 && expenseAlertsOn && cycleIncome > 0) {
      final margin = (cycleIncome - cycleExpenses) / cycleIncome;
      if (margin >= 0 && margin < 0.10) {
        final dedupKey = 'margin_warning_${_todayKey()}';
        if (!await _notifService.existsWithDedupKey(dedupKey)) {
          await _emit(
            type: 'margin_warning',
            title: 'Te estás acercando a tu límite',
            message: 'Tu margen entre ingresos y gastos de este ciclo es menor al 10%. '
                'Vale la pena revisar tus gastos para no quedarte corto.',
            dedupKey: dedupKey,
          );
          remaining--;
        }
      }
    }

    // Regla 2: gasto de una categoría en el mes actual supera el 200% de
    // su promedio histórico (mínimo 3 registros previos en esa categoría).
    if (remaining > 0 && expenseAlertsOn) {
      final spikeCategory = _findCategorySpike(expenses);
      if (spikeCategory != null) {
        final dedupKey = 'expense_alert_${spikeCategory}_${_todayKey()}';
        if (!await _notifService.existsWithDedupKey(dedupKey)) {
          await _emit(
            type: 'expense_alert',
            title: 'Gasto arriba de tu promedio',
            message: 'Tu gasto en $spikeCategory superó el 200% de tu promedio histórico.',
            dedupKey: dedupKey,
          );
          remaining--;
        }
      }
    }

    // Regla 3: una meta llega al 50% (una sola vez por meta).
    if (remaining > 0 && goalAlertsOn) {
      for (final goal in goals.where((g) => !g.completed)) {
        if (goal.targetAmount == 0) continue;
        final percent = goal.currentAmount / goal.targetAmount;
        if (percent >= 0.5) {
          final dedupKey = 'goal_progress_${goal.id}_50';
          if (!await _notifService.existsWithDedupKey(dedupKey)) {
            await _emit(
              type: 'goal_progress',
              title: 'Vas al 50% de tu meta',
              message: 'Ya llevas \$${goal.currentAmount} de \$${goal.targetAmount} para "${goal.name}".',
              dedupKey: dedupKey,
            );
            remaining--;
            break;
          }
        }
      }
    }

    // Regla 4: contexto del ciclo.
    // 4a: gastos > ingresos del ciclo -> mensaje de apoyo.
    // 4b: margen >= 20% y sin Modo de Estabilidad -> presión de ahorro.
    if (remaining > 0 && expenseAlertsOn && currentCycle != null) {
      final dedupKey = 'context_message_${_todayKey()}';
      if (!await _notifService.existsWithDedupKey(dedupKey)) {
        if (cycleExpenses > 0 && cycleExpenses > cycleIncome) {
          await _emit(
            type: 'support_message',
            title: 'Estamos contigo',
            message: 'Notamos que tus gastos superaron tus ingresos este ciclo. '
                'No estás solo: revisa tu progreso y ajusta lo que puedas, un paso a la vez.',
            dedupKey: dedupKey,
          );
          remaining--;
        } else if (cycleIncome > 0) {
          final marginPercent = ((cycleIncome - cycleExpenses) / cycleIncome * 100).round();
          final financialMode = await _financialModeService.evaluate();
          if (marginPercent >= 20 && !financialMode.isStabilityMode) {
            await _emit(
              type: 'saving_pressure',
              title: 'Vas bien, ¡aprovecha!',
              message: 'Te está sobrando un $marginPercent% de tu ingreso este ciclo. '
                  'Considera aportar un poco más a tus metas de ahorro.',
              dedupKey: dedupKey,
            );
            remaining--;
          }
        }
      }
    }
  }

  /// Compara el gasto de cada categoría en el mes actual contra el
  /// promedio de sus registros previos (mínimo 3 registros previos).
  String? _findCategorySpike(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final previousByCategory = <String, List<int>>{};
    final thisMonthByCategory = <String, int>{};

    for (final e in expenses) {
      final isThisMonth = e.date.year == now.year && e.date.month == now.month;
      if (isThisMonth) {
        thisMonthByCategory[e.category] = (thisMonthByCategory[e.category] ?? 0) + e.amount;
      } else {
        previousByCategory.putIfAbsent(e.category, () => []).add(e.amount);
      }
    }

    for (final entry in thisMonthByCategory.entries) {
      final history = previousByCategory[entry.key] ?? [];
      if (history.length < 3) continue;
      final average = history.reduce((a, b) => a + b) / history.length;
      if (average > 0 && entry.value > average * 2) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> markRead(String id) => _notifService.markRead(id);
  Future<void> markAllRead() => _notifService.markAllRead();
}
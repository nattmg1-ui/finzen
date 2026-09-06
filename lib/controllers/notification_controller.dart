import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/expense_model.dart';
import '../services/notification_service.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/savings_goal_service.dart';
import '../services/firestore_service.dart';
import '../services/local_notification_service.dart';
import '../services/financial_mode_service.dart';

/// El "motor" de notificaciones del Módulo 6. Se ejecuta cada vez que
/// se llama a evaluateAndGenerate() (normalmente al abrir el
/// Dashboard) y decide si toca generar alguna notificación nueva,
/// respetando: horario silencioso, límite de 2/día, preferencias del
/// usuario, y el contexto financiero (gastos vs ingresos). Cada
/// notificación generada también dispara un banner real del sistema.
class NotificationController extends ChangeNotifier {
  final NotificationService _notifService = NotificationService();
  final LocalNotificationService _localNotifService = LocalNotificationService();
  final IncomeService _incomeService = IncomeService();
  final ExpenseService _expenseService = ExpenseService();
  final SavingsGoalService _goalService = SavingsGoalService();
  final FirestoreService _firestoreService = FirestoreService();
  final FinancialModeService _financialModeService = FinancialModeService();

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

  /// Guarda la notificación en Firestore (para el historial dentro de
  /// la app) Y dispara el banner real del sistema operativo al mismo
  /// tiempo, con el mismo título y mensaje.
  Future<void> _emit({
    required String type,
    required String title,
    required String message,
    required String dedupKey,
  }) async {
    await _notifService.add(type: type, title: title, message: message, dedupKey: dedupKey);
    await _localNotifService.show(title: title, body: message);
  }

  /// Corre las reglas del Módulo 6 y genera hasta 2 notificaciones
  /// nuevas por día. No hace nada si está en horario silencioso o si
  /// ya se alcanzó el límite diario.
  Future<void> evaluateAndGenerate() async {
    if (_isQuietHours) return;

    var remaining = maxPerDay - await _notifService.countCreatedToday();
    if (remaining <= 0) return;

    final user = await _firestoreService.fetchCurrentUserProfile();
    final incomes = await _incomeService.watchIncomes().first;
    final expenses = await _expenseService.watchExpenses().first;
    final goals = await _goalService.watchGoals().first;

    final totalIncome = incomes.fold<int>(0, (sum, i) => sum + i.amount);
    final totalExpenses = expenses.fold<int>(0, (sum, e) => sum + e.amount);

    final expenseAlertsOn = user?.notifyExpenseAlerts ?? true;
    final goalAlertsOn = user?.notifyGoalAlerts ?? true;

    // Regla 1: margen entre ingreso y gasto menor al 10% (RQF explícito).
    if (remaining > 0 && expenseAlertsOn && totalIncome > 0) {
      final margin = (totalIncome - totalExpenses) / totalIncome;
      if (margin < 0.10 && margin >= 0) {
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

    // Regla 2: alguna categoría gastó más del 200% de su promedio histórico.
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

    // Regla 3: alguna meta llegó al 50% (una sola vez por meta, no cada día).
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

    // Regla 4: mensaje de contexto — apoyo si gastos>ingresos, presión
    // de ahorro si te está sobrando bastante (RQNF de tono adaptativo).
    if (remaining > 0 && expenseAlertsOn && totalIncome > 0)  {
      final dedupKey = 'context_message_${_todayKey()}';
      if (!await _notifService.existsWithDedupKey(dedupKey)) {
        if (totalExpenses > totalIncome) {
          await _emit(
            type: 'support_message',
            title: 'Estamos contigo',
            message: 'Notamos que tus gastos superaron tus ingresos este ciclo. '
                'No estás solo: revisa tu progreso y ajusta lo que puedas, un paso a la vez.',
            dedupKey: dedupKey,
          );
          remaining--;
        } else {
          final marginPercent = ((totalIncome - totalExpenses) / totalIncome * 100).round();
          final financialMode = await _financialModeService.evaluate();
          // RQNF: si los gastos esenciales superan el ingreso, se
          // suprime la notificación de presión de ahorro.
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

  /// Compara el gasto de este mes por categoría contra el promedio
  /// histórico de esa misma categoría (simplificación de "promedio de
  /// los últimos 3 meses" del maquetado, usando todo el historial
  /// disponible en vez de exactamente 3 ciclos).
  String? _findCategorySpike(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final byCategoryAll = <String, List<int>>{};
    final byCategoryThisMonth = <String, int>{};

    for (final e in expenses) {
      byCategoryAll.putIfAbsent(e.category, () => []).add(e.amount);
      if (e.date.year == now.year && e.date.month == now.month) {
        byCategoryThisMonth[e.category] = (byCategoryThisMonth[e.category] ?? 0) + e.amount;
      }
    }

    for (final entry in byCategoryThisMonth.entries) {
      final history = byCategoryAll[entry.key] ?? [];
      if (history.length < 3) continue;
      final avg = history.reduce((a, b) => a + b) / history.length;
      if (avg > 0 && entry.value > avg * 2) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> markRead(String id) => _notifService.markRead(id);
  Future<void> markAllRead() => _notifService.markAllRead();
}
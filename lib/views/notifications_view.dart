import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final NotificationController _controller = NotificationController();

  static const Map<String, IconData> _icons = {
    'expense_alert': Icons.warning_amber_rounded,
    'goal_progress': Icons.track_changes,
    'margin_warning': Icons.trending_down,
    'support_message': Icons.volunteer_activism,
    'saving_pressure': Icons.lightbulb_outline,
  };

  static const Map<String, Color> _iconBg = {
    'expense_alert': Color(0xFFF5C6B3),
    'goal_progress': Color(0xFFD8ECD9),
    'margin_warning': Color(0xFFF5C6B3),
    'support_message': Color(0xFFE0DDF5),
    'saving_pressure': Color(0xFFFCE9CF),
  };

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'HOY';
    if (diff == 1) return 'AYER';
    if (diff <= 7) return 'ESTA SEMANA';
    return 'ANTERIOR';
  }

  String _formatTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'a.m.' : 'p.m.';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  Map<String, List<NotificationModel>> _groupedNotifications() {
    final map = <String, List<NotificationModel>>{};
    for (final n in _controller.notifications) {
      final label = _groupLabel(n.createdAt);
      map.putIfAbsent(label, () => []).add(n);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final grouped = _groupedNotifications();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones'),
            elevation: 0,
            actions: [
              if (_controller.unreadCount > 0)
                TextButton(
                  onPressed: () => _controller.markAllRead(),
                  child: const Text('Marcar todas'),
                ),
            ],
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.notifications.isEmpty
                  ? const Center(child: Text('No tienes notificaciones todavía'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: grouped.entries.expand((entry) {
                        return [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...entry.value.map((n) => _buildNotificationTile(n)),
                        ];
                      }).toList(),
                    ),
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    return InkWell(
      onTap: () => _controller.markRead(n.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _iconBg[n.type] ?? Colors.grey.shade200, shape: BoxShape.circle),
              child: Icon(_icons[n.type] ?? Icons.notifications, size: 20, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(n.message, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(_formatTime(n.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            if (!n.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: Color(0xFFE89A3C), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
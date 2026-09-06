import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';
import '../widgets/app_drawer.dart';
import 'home_content_view.dart';
import 'notifications_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final NotificationController _notificationController = NotificationController();

  @override
  void initState() {
    super.initState();
    _notificationController.evaluateAndGenerate();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notificationController,
      builder: (context, child) {
        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: const Text('FinZen'),
            elevation: 0,
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsView())),
                  ),
                  if (_notificationController.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${_notificationController.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: const HomeContentView(),
        );
      },
    );
  }
}
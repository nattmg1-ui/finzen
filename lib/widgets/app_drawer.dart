import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../views/income_view.dart';
import '../views/expense_view.dart';
import '../views/savings_goal_view.dart';
import '../views/reports_view.dart';
import '../views/recommendations_view.dart';
import '../views/education_view.dart';
import '../views/notifications_view.dart';
import '../views/profile_view.dart';

/// Menú lateral: GENERAL / ANÁLISIS / CUENTA, con "Inicio" resaltado
/// y "Cerrar sesión" separado abajo.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _sectionLabel('GENERAL'),
            _menuItem(context, icon: Icons.home_outlined, label: 'Inicio', isActive: true, onTap: () => Navigator.pop(context)),
            _menuItem(context, icon: Icons.trending_up, label: 'Ingresos', onTap: () => _navigate(context, const IncomeView())),
            _menuItem(context, icon: Icons.receipt_long_outlined, label: 'Gastos', onTap: () => _navigate(context, const ExpenseView())),
            _menuItem(context, icon: Icons.track_changes_outlined, label: 'Metas de ahorro', onTap: () => _navigate(context, const SavingsGoalView())),
            const Divider(height: 24),
            _sectionLabel('ANÁLISIS'),
            _menuItem(context, icon: Icons.bar_chart_outlined, label: 'Reportes', onTap: () => _navigate(context, const ReportsView())),
            _menuItem(context, icon: Icons.lightbulb_outline, label: 'Recomendaciones', onTap: () => _navigate(context, const RecommendationsView())),
            _menuItem(context, icon: Icons.menu_book_outlined, label: 'Educación financiera', onTap: () => _navigate(context, const EducationView())),
            const Divider(height: 24),
            _sectionLabel('CUENTA'),
            _menuItem(context, icon: Icons.notifications_outlined, label: 'Notificaciones', onTap: () => _navigate(context, const NotificationsView())),
            _menuItem(context, icon: Icons.settings_outlined, label: 'Configuración', onTap: () => _navigate(context, const ProfileView())),
            const Spacer(),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _menuItem(
              context,
              icon: Icons.logout,
              label: 'Cerrar sesión',
              color: Colors.red,
              onTap: () => _confirmSignOut(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE89A3C)])
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : color),
        title: Text(
          label,
          style: TextStyle(color: isActive ? Colors.white : color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
        onTap: onTap,
      ),
    );
  }

  void _navigate(BuildContext context, Widget view) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (c) => view));
  }

  void _confirmSignOut(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Vas a salir de tu cuenta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await AuthService().signOut();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
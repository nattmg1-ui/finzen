import 'package:flutter/material.dart';
import '../controllers/profile_controller.dart';
import '../utils/dialogs.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileController _controller = ProfileController();

  static const List<String> _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  void _openEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar nombre'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final success = await _controller.updateName(controller.text);
                if (!dialogContext.mounted) return;
                if (success) {
                  Navigator.pop(dialogContext);
                } else {
                  showErrorDialog(context, _controller.errorMessage ?? 'Error');
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _openChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final success = await _controller.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                  confirmPassword: confirmController.text,
                );
                if (!dialogContext.mounted) return;
                if (success) {
                  Navigator.pop(dialogContext);
                  showErrorDialog(context, 'Contraseña actualizada', title: 'Listo');
                } else {
                  showErrorDialog(context, _controller.errorMessage ?? 'Error');
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableRow({required String label, required String value, required VoidCallback onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(value.isEmpty ? '—' : value)),
                GestureDetector(
                  onTap: onEdit,
                  child: const Text('Editar', style: TextStyle(color: Color(0xFFE89A3C), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Text(value.isEmpty ? '—' : value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final user = _controller.user;

        return Scaffold(
          appBar: AppBar(title: const Text('Configuración'), elevation: 0),
          body: _controller.isLoading || user == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFE89A3C),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name.isEmpty ? 'Usuario' : user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (user.createdAt != null)
                              Text(
                                'Miembro desde ${_months[user.createdAt!.month - 1]} ${user.createdAt!.year}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    const Text('DATOS PERSONALES', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildEditableRow(
                      label: 'Nombre',
                      value: user.name,
                      onEdit: () => _openEditNameDialog(user.name),
                    ),
                    _buildReadOnlyRow(label: 'Correo electrónico', value: user.email),

                    InkWell(
                      onTap: _openChangePasswordDialog,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.key, size: 20),
                            SizedBox(width: 12),
                            Expanded(child: Text('Cambiar contraseña')),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('APARIENCIA', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _controller.setThemeMode('light'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: user.themeMode == 'light' ? const Color(0xFFE89A3C) : Colors.white,
                                border: Border.all(color: user.themeMode == 'light' ? const Color(0xFFE89A3C) : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.wb_sunny_outlined, color: user.themeMode == 'light' ? Colors.white : Colors.black54),
                                  const SizedBox(height: 6),
                                  Text('Claro', style: TextStyle(color: user.themeMode == 'light' ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _controller.setThemeMode('dark'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: user.themeMode == 'dark' ? const Color(0xFFE89A3C) : Colors.white,
                                border: Border.all(color: user.themeMode == 'dark' ? const Color(0xFFE89A3C) : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.nightlight_outlined, color: user.themeMode == 'dark' ? Colors.white : Colors.black54),
                                  const SizedBox(height: 6),
                                  Text('Oscuro', style: TextStyle(color: user.themeMode == 'dark' ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text('NOTIFICACIONES', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.warning_amber_rounded),
                            title: const Text('Alertas de gasto'),
                            subtitle: const Text('Cuando superas tu promedio', style: TextStyle(fontSize: 12)),
                            value: user.notifyExpenseAlerts,
                            activeColor: const Color(0xFFE89A3C),
                            onChanged: (value) => _controller.toggleExpenseAlerts(value),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            secondary: const Icon(Icons.track_changes),
                            title: const Text('Metas de ahorro'),
                            subtitle: const Text('Avances y recordatorios', style: TextStyle(fontSize: 12)),
                            value: user.notifyGoalAlerts,
                            activeColor: const Color(0xFFE89A3C),
                            onChanged: (value) => _controller.toggleGoalAlerts(value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
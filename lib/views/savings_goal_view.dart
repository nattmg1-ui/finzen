import 'package:flutter/material.dart';
import '../controllers/savings_goal_controller.dart';
import '../models/savings_goal_model.dart';
import '../utils/dialogs.dart';

class SavingsGoalView extends StatefulWidget {
  const SavingsGoalView({super.key});

  @override
  State<SavingsGoalView> createState() => _SavingsGoalViewState();
}

class _SavingsGoalViewState extends State<SavingsGoalView> {
  final SavingsGoalController _controller = SavingsGoalController();

  Map<String, Color> _priorityPillBackground(String priority) {
    switch (priority) {
      case 'Alta':
        return {'bg': const Color(0xFFF5C6B3), 'text': const Color(0xFF8B3A2B)};
      case 'Media':
        return {'bg': const Color(0xFFE0DDF5), 'text': const Color(0xFF4B3F9E)};
      default:
        return {'bg': const Color(0xFFD8ECD9), 'text': const Color(0xFF2E6B3E)};
    }
  }

  static const List<Map<String, Color>> _cardPaletteLight = [
    {'bg': Color(0xFFE3F2E9), 'bar': Color(0xFF1B6B4E)},
    {'bg': Color(0xFFEDEAFB), 'bar': Color(0xFF5B4FE0)},
    {'bg': Color(0xFFFBE4DC), 'bar': Color(0xFFE0562D)},
  ];

  static const List<Map<String, Color>> _cardPaletteDark = [
    {'bg': Color(0xFF1E332A), 'bar': Color(0xFF4CAF82)},
    {'bg': Color(0xFF272449), 'bar': Color(0xFF8B82F0)},
    {'bg': Color(0xFF3A2620), 'bar': Color(0xFFE0824F)},
  ];

  List<Map<String, Color>> _cardPalette(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _cardPaletteDark : _cardPaletteLight;
  }

  void _openGoalSheet({SavingsGoalModel? existingGoal}) {
    final isEditing = existingGoal != null;
    final nameController = TextEditingController(text: existingGoal?.name ?? '');
    final amountController = TextEditingController(text: existingGoal?.targetAmount.toString() ?? '');
    String selectedPriority = existingGoal?.priority ?? 'Media';
    String selectedType = existingGoal?.type ?? 'Opcional';
    DateTime selectedDeadline = existingGoal?.deadline ?? DateTime.now().add(const Duration(days: 90));
    final maxDeadline = _controller.maxAllowedDeadline();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'Editar meta' : 'Nueva meta de ahorro',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    const Text('Nombre de la meta', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(hintText: 'Ej. Viaje a la playa', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 20),

                    const Text('Monto objetivo (MXN)', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(prefixText: '\$ ', hintText: '0', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 20),

                    const Text('Prioridad', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: SavingsGoalController.priorities.map((p) {
                        final isSelected = selectedPriority == p;
                        final colors = _priorityPillBackground(p);
                        return ChoiceChip(
                          label: Text(p),
                          selected: isSelected,
                          onSelected: (_) => setSheetState(() => selectedPriority = p),
                          selectedColor: colors['bg'],
                          labelStyle: TextStyle(color: isSelected ? colors['text'] : null, fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('Tipo de meta', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text(
                      'Vital: fondos de emergencia, deudas urgentes. Opcional: viajes, compras, deseos.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: SavingsGoalController.types.map((t) {
                        final isSelected = selectedType == t;
                        return ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (_) => setSheetState(() => selectedType = t),
                          selectedColor: const Color(0xFFE89A3C),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : null, fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('Fecha límite', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedDeadline.isAfter(maxDeadline) ? maxDeadline : selectedDeadline,
                          firstDate: DateTime.now().add(const Duration(days: 1)),
                          lastDate: maxDeadline,
                        );
                        if (picked != null) setSheetState(() => selectedDeadline = picked);
                      },
                      child: Text('${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Máximo ${SavingsGoalController.maxYearsAhead} años a partir de hoy. Si la fecha no es viable según tu ingreso, el sistema la ajustará al guardar.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE89A3C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final success = isEditing
                              ? await _controller.editGoal(
                                  goalId: existingGoal.id,
                                  name: nameController.text,
                                  targetAmountText: amountController.text,
                                  currentAmount: existingGoal.currentAmount,
                                  priority: selectedPriority,
                                  type: selectedType,
                                  deadline: selectedDeadline,
                                )
                              : await _controller.addGoal(
                                  name: nameController.text,
                                  targetAmountText: amountController.text,
                                  priority: selectedPriority,
                                  type: selectedType,
                                  deadline: selectedDeadline,
                                );

                          if (!sheetContext.mounted) return;

                          if (success) {
                            Navigator.pop(sheetContext);
                            if (_controller.adjustmentMessage != null) {
                              _showInfoDialog('Fecha ajustada', _controller.adjustmentMessage!);
                              _controller.adjustmentMessage = null;
                            }
                          } else {
                            showErrorDialog(sheetContext, _controller.errorMessage ?? 'Error');
                          }
                        },
                        child: Text(isEditing ? 'Guardar cambios' : 'Crear meta',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    if (isEditing) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _startDeleteFlow(existingGoal);
                          },
                          child: const Text('Eliminar meta', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Entendido'))],
      ),
    );
  }

  void _startDeleteFlow(SavingsGoalModel goal) {
    if (goal.currentAmount <= 0) {
      _confirmDeleteDialog(goal, destinationGoalId: null);
      return;
    }
    final otherActiveGoals = _controller.activeGoalsExcept(goal.id);
    if (otherActiveGoals.isEmpty) {
      _confirmDeleteDialog(goal, destinationGoalId: null);
      return;
    }
    _showDestinationPicker(
      title: '¿A dónde va el saldo de "${goal.name}"?',
      amountLabel: '\$${goal.currentAmount} MXN acumulados',
      otherGoals: otherActiveGoals,
      onChosen: (destinationId) => _confirmDeleteDialog(goal, destinationGoalId: destinationId),
    );
  }

  void _confirmDeleteDialog(SavingsGoalModel goal, {String? destinationGoalId}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar esta meta?'),
        content: Text('${goal.name}. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final success = await _controller.deleteGoal(goal, destinationGoalId: destinationGoalId);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!success) {
                showErrorDialog(context, _controller.errorMessage ?? 'Error');
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDestinationPicker({
    required String title,
    required String amountLabel,
    required List<SavingsGoalModel> otherGoals,
    required void Function(String? destinationGoalId) onChosen,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amountLabel, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Saldo general'),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    onChosen(null);
                  },
                ),
                const Divider(),
                ...otherGoals.map((g) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(g.name),
                      subtitle: Text('\$${g.currentAmount} de \$${g.targetAmount}'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        onChosen(g.id);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddFundsDialog(SavingsGoalModel goal) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Aportar a "${goal.name}"'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final result = await _controller.addFunds(goal, amountController.text);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (!result.success) {
                showErrorDialog(context, _controller.errorMessage ?? 'Error');
                return;
              }

              if (result.justCompleted) {
                final otherActiveGoals = _controller.activeGoalsExcept(goal.id);
                if (otherActiveGoals.isEmpty) {
                  _showInfoDialog('¡Meta completada! 🎉', 'Tu saldo se reintegró al saldo general.');
                  return;
                }
                _showDestinationPicker(
                  title: '¡Completaste "${goal.name}"! ¿A dónde va el saldo?',
                  amountLabel: '\$${goal.currentAmount + (int.tryParse(amountController.text) ?? 0)} MXN acumulados',
                  otherGoals: otherActiveGoals,
                  onChosen: (destinationId) async {
                    await _controller.redirectCompletedGoalFunds(goal, destinationGoalId: destinationId);
                  },
                );
              }
            },
            child: const Text('Aportar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRecalibrate(SavingsGoalModel goal) async {
    final success = await _controller.recalibrateDeadline(goal);
    if (!mounted) return;
    if (success) {
      _showInfoDialog('Recalculado', _controller.adjustmentMessage ?? 'Listo.');
      _controller.adjustmentMessage = null;
    } else {
      showErrorDialog(context, _controller.errorMessage ?? 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Metas de ahorro'), elevation: 0),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFE89A3C),
            onPressed: () => _openGoalSheet(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.goals.isEmpty
                  ? const Center(child: Text('Aún no tienes metas de ahorro'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _controller.goals.length,
                      itemBuilder: (context, index) {
                        final goal = _controller.goals[index];
                        final palette = _cardPalette(context)[index % _cardPalette(context).length];
                        final pillColors = _priorityPillBackground(goal.priority);
                        const cardTextColor = Colors.black87;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: palette['bg'], borderRadius: BorderRadius.circular(16)),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openGoalSheet(existingGoal: goal),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            goal.name,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cardTextColor),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: BoxDecoration(
                                                color: cardTextColor.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                goal.type,
                                                style: TextStyle(color: cardTextColor.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: pillColors['bg'], borderRadius: BorderRadius.circular(20)),
                                              child: Text(
                                                goal.priority,
                                                style: TextStyle(color: pillColors['text'], fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      value: goal.progress,
                                      backgroundColor: Colors.white.withOpacity(isDark ? 0.15 : 0.6),
                                      color: goal.completed ? Colors.green : palette['bar'],
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('\$${goal.currentAmount} de \$${goal.targetAmount}', style: const TextStyle(fontSize: 13, color: cardTextColor)),
                                        Row(
                                          children: [
                                            Text('Meta: ${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}', style: const TextStyle(fontSize: 13, color: cardTextColor)),
                                            if (!goal.completed) ...[
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () => _handleRecalibrate(goal),
                                                child: Icon(Icons.refresh, size: 16, color: cardTextColor.withOpacity(0.7)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (goal.completed)
                                      const Text('¡Meta completada! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                                    else if (goal.paused)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(isDark ? 0.15 : 0.7), borderRadius: BorderRadius.circular(20)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.pause_circle_outline, size: 16, color: cardTextColor.withOpacity(0.7)),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                SavingsGoalController.pausedMessage,
                                                style: TextStyle(fontSize: 12, color: cardTextColor.withOpacity(0.7)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => _openAddFundsDialog(goal),
                                          child: const Text('Aportar'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
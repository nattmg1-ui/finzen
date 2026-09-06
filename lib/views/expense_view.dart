import 'package:flutter/material.dart';
import '../controllers/expense_controller.dart';
import '../data/expense_categories.dart';
import '../models/expense_model.dart';
import '../utils/dialogs.dart';

class ExpenseView extends StatefulWidget {
  const ExpenseView({super.key});

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  final ExpenseController _controller = ExpenseController();

  static const Map<String, IconData> _categoryIcons = {
    'Alimentación': Icons.restaurant,
    'Transporte': Icons.directions_bus,
    'Entretenimiento y salidas': Icons.sports_esports,
    'Servicios y pagos fijos': Icons.receipt_long,
    'Ropa y accesorios': Icons.checkroom,
    'Salud y bienestar': Icons.favorite,
    'Educación': Icons.school,
    'Otros': Icons.category,
  };

  void _openExpenseSheet({ExpenseModel? existingExpense}) {
    final isEditing = existingExpense != null;

    String selectedCategory = existingExpense?.category ?? expenseCategories.keys.first;
    String? selectedSubcategory = existingExpense?.subcategory;
    final amountController = TextEditingController(text: existingExpense?.amount.toString() ?? '');
    final descriptionController = TextEditingController(text: existingExpense?.description ?? '');
    DateTime selectedDate = existingExpense?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;

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
                    Text(
                      isEditing ? 'Editar gasto' : 'Agregar gasto',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    const Text('Categoría', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: expenseCategories.keys.map((catName) {
                        final isSelected = selectedCategory == catName;
                        return GestureDetector(
                          onTap: () => setSheetState(() {
                            selectedCategory = catName;
                            selectedSubcategory = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE89A3C).withOpacity(0.15) : scheme.surfaceContainerHighest,
                              border: Border.all(
                                color: isSelected ? const Color(0xFFE89A3C) : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcons[catName],
                                  size: 18,
                                  color: isSelected ? const Color(0xFFE89A3C) : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(catName, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('Subcategoría', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (expenseCategories[selectedCategory] ?? []).map((sub) {
                        final isSelected = selectedSubcategory == sub;
                        return ChoiceChip(
                          label: Text(sub, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) => setSheetState(() => selectedSubcategory = sub),
                          selectedColor: const Color(0xFFE89A3C),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('Fecha', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setSheetState(() => selectedDate = picked);
                      },
                      child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    ),
                    const SizedBox(height: 20),

                    const Text('Monto (MXN)', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        hintText: '0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Descripción breve (opcional)', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Ej. Comida con amigos',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
                          if (selectedSubcategory == null) {
                            showErrorDialog(sheetContext, 'Selecciona una subcategoría');
                            return;
                          }

                          final success = isEditing
                              ? await _controller.editExpense(
                                  expenseId: existingExpense.id,
                                  category: selectedCategory,
                                  subcategory: selectedSubcategory!,
                                  amountText: amountController.text,
                                  description: descriptionController.text,
                                  date: selectedDate,
                                )
                              : await _controller.addExpense(
                                  category: selectedCategory,
                                  subcategory: selectedSubcategory!,
                                  amountText: amountController.text,
                                  description: descriptionController.text,
                                  date: selectedDate,
                                );

                          if (!sheetContext.mounted) return;
                          if (success) {
                            Navigator.pop(sheetContext);
                          } else {
                            showErrorDialog(sheetContext, _controller.errorMessage ?? 'Error');
                          }
                        },
                        child: Text(
                          isEditing ? 'Guardar cambios' : 'Guardar gasto',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
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
                            _maybeDelete(existingExpense);
                          },
                          child: const Text('Eliminar gasto', style: TextStyle(fontWeight: FontWeight.bold)),
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

  /// Revisa el bloqueo de 1 mes ANTES de abrir el editor.
  void _maybeEdit(ExpenseModel expense) {
    if (_controller.isLocked(expense)) {
      showErrorDialog(
        context,
        'Este gasto tiene más de un mes registrado, así que ya no se puede modificar.',
      );
      return;
    }
    _openExpenseSheet(existingExpense: expense);
  }

  void _maybeDelete(ExpenseModel expense) {
    if (_controller.isLocked(expense)) {
      showErrorDialog(
        context,
        'Este gasto tiene más de un mes registrado, así que ya no se puede eliminar.',
      );
      return;
    }
    _confirmDelete(expense);
  }

  void _confirmDelete(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Eliminar este gasto?'),
          content: Text('${expense.subcategory} · \$${expense.amount} MXN. Esta acción no se puede deshacer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final success = await _controller.deleteExpense(expense.id);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!success) {
                  showErrorDialog(context, _controller.errorMessage ?? 'No se pudo eliminar');
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, ExpenseFilter value) {
    final isSelected = _controller.filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _controller.setFilter(value),
        selectedColor: const Color(0xFFE89A3C),
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final expenses = _controller.filteredExpenses;

        return Scaffold(
          appBar: AppBar(title: const Text('Gastos'), elevation: 0),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFE89A3C),
            onPressed: () => _openExpenseSheet(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total gastado', style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text('\$${_controller.totalSpent} MXN', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildFilterChip('Todos', ExpenseFilter.todos),
                          _buildFilterChip('Vital', ExpenseFilter.vital),
                          _buildFilterChip('Opcional', ExpenseFilter.opcional),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: expenses.isEmpty
                          ? const Center(child: Text('Aún no tienes gastos registrados'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: expenses.length,
                              itemBuilder: (context, index) {
                                final expense = expenses[index];
                                final locked = _controller.isLocked(expense);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Icon(_categoryIcons[expense.category] ?? Icons.category),
                                    title: Text(expense.subcategory),
                                    subtitle: Text(
                                      '${expense.category} · ${expense.essentialType} · ${expense.date.day}/${expense.date.month}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('\$${expense.amount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (locked) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                        ],
                                      ],
                                    ),
                                    onTap: () => _maybeEdit(expense),
                                    onLongPress: () => _maybeDelete(expense),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
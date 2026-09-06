import 'package:flutter/material.dart';
import '../controllers/income_controller.dart';
import '../models/income_model.dart';
import '../services/firestore_service.dart';
import '../utils/dialogs.dart';

class IncomeView extends StatefulWidget {
  const IncomeView({super.key});

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView> {
  final IncomeController _controller = IncomeController();
  final FirestoreService _firestoreService = FirestoreService();

  static const List<String> _allTypes = ['Empleado', 'Freelance', 'Negocio propio', 'Mixto', 'Mesada'];
  static const List<String> _frequencies = ['Semanal', 'Quincenal', 'Mensual'];

  List<String> _suggestedTypes = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestedTypes();
  }

  Future<void> _loadSuggestedTypes() async {
    final user = await _firestoreService.fetchCurrentUserProfile();
    final raw = user?.diagnosis?['incomeSourceType'];
    if (raw is List) {
      setState(() {
        _suggestedTypes = raw.map((e) => e.toString()).toList();
      });
    }
  }

  List<String> get _orderedTypes {
    final rest = _allTypes.where((t) => !_suggestedTypes.contains(t)).toList();
    return [..._suggestedTypes, ...rest];
  }

  void _openIncomeSheet({IncomeModel? existingIncome}) {
    final isEditing = existingIncome != null;
    String selectedType = existingIncome?.type ?? (_suggestedTypes.isNotEmpty ? _suggestedTypes.first : _allTypes.first);
    String selectedFrequency = existingIncome?.frequency ?? _frequencies.last;
    final amountController = TextEditingController(text: existingIncome?.amount.toString() ?? '');
    DateTime selectedDate = existingIncome?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'Editar ingreso' : 'Agregar ingreso',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    const Text('Tipo de fuente de ingreso', style: TextStyle(fontWeight: FontWeight.w500)),
                    if (!isEditing && _suggestedTypes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Según tu diagnóstico: ${_suggestedTypes.join(", ")}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _orderedTypes.map((type) {
                        final isSelected = selectedType == type;
                        final isSuggested = !isEditing && _suggestedTypes.contains(type);
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSuggested) const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.star, size: 14, color: Color(0xFFE89A3C)),
                              ),
                              Text(type),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (_) => setSheetState(() => selectedType = type),
                          selectedColor: const Color(0xFFE89A3C),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('Frecuencia', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _frequencies.map((freq) {
                        final isSelected = selectedFrequency == freq;
                        return ChoiceChip(
                          label: Text(freq),
                          selected: isSelected,
                          onSelected: (_) => setSheetState(() => selectedFrequency = freq),
                          selectedColor: const Color(0xFFE89A3C),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('¿Desde cuándo tienes este ingreso?', style: TextStyle(fontWeight: FontWeight.w500)),
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

                    const Text('Monto aproximado (MXN)', style: TextStyle(fontWeight: FontWeight.w500)),
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
                              ? await _controller.editIncome(
                                  incomeId: existingIncome.id,
                                  type: selectedType,
                                  frequency: selectedFrequency,
                                  amountText: amountController.text,
                                  date: selectedDate,
                                )
                              : await _controller.addIncome(
                                  type: selectedType,
                                  frequency: selectedFrequency,
                                  amountText: amountController.text,
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
                          isEditing ? 'Guardar cambios' : 'Guardar ingreso',
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
                            _maybeDelete(existingIncome);
                          },
                          child: const Text('Eliminar ingreso', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _maybeEdit(IncomeModel income) {
    if (_controller.isLocked(income)) {
      showErrorDialog(context, 'Este ingreso tiene más de un mes registrado, así que ya no se puede modificar.');
      return;
    }
    _openIncomeSheet(existingIncome: income);
  }

  void _maybeDelete(IncomeModel income) {
    if (_controller.isLocked(income)) {
      showErrorDialog(context, 'Este ingreso tiene más de un mes registrado, así que ya no se puede eliminar.');
      return;
    }
    _confirmDelete(income);
  }

  void _confirmDelete(IncomeModel income) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Eliminar este ingreso?'),
          content: Text('${income.type} · \$${income.amount} MXN. Esta acción no se puede deshacer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final success = await _controller.deleteIncome(income.id);
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ingresos'), elevation: 0),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFE89A3C),
            onPressed: () => _openIncomeSheet(),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFE89A3C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingreso total mensual', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_controller.totalMonthlyIncome} MXN',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _controller.incomes.isEmpty
                          ? const Center(child: Text('Aún no tienes fuentes de ingreso registradas'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _controller.incomes.length,
                              itemBuilder: (context, index) {
                                final income = _controller.incomes[index];
                                final locked = _controller.isLocked(income);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(income.type),
                                    subtitle: Text('${income.frequency} · desde ${income.date.day}/${income.date.month}/${income.date.year}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('\$${income.amount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (locked) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                        ],
                                      ],
                                    ),
                                    onTap: () => _maybeEdit(income),
                                    onLongPress: () => _maybeDelete(income),
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
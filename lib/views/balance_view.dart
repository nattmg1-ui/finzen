import 'package:flutter/material.dart';
import '../controllers/balance_controller.dart';

class BalanceView extends StatefulWidget {
  const BalanceView({super.key});

  @override
  State<BalanceView> createState() => _BalanceViewState();
}

class _BalanceViewState extends State<BalanceView> {
  final BalanceController _controller = BalanceController();

  Widget _buildCard({required String label, required int amount, required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text('\$$amount MXN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Saldo general'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFFE89A3C), borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Disponible ahora', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(
                              '\$${_controller.generalBalance} MXN',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Cómo se calcula', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      _buildCard(label: 'Ingreso total', amount: _controller.totalIncome, color: Colors.green, icon: Icons.arrow_downward),
                      _buildCard(label: 'Gasto total', amount: -_controller.totalExpenses, color: Colors.red, icon: Icons.arrow_upward),
                      _buildCard(
                        label: 'Aportado a metas activas',
                        amount: -_controller.totalAllocatedToGoals,
                        color: Colors.blue,
                        icon: Icons.flag_outlined,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
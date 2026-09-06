import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import 'expense_view.dart';
import 'savings_goal_view.dart';

class HomeContentView extends StatefulWidget {
  const HomeContentView({super.key});

  @override
  State<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends State<HomeContentView> {
  final HomeController _controller = HomeController();

  static const List<String> _weekDays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
  static const List<String> _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  String _formattedDate(DateTime date) {
    final weekday = _weekDays[date.weekday - 1];
    final month = _months[date.month - 1];
    final capitalized = weekday[0].toUpperCase() + weekday.substring(1);
    return '$capitalized, ${date.day} de $month';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final topCategories = _controller.topCategories;
        final maxCategoryAmount = topCategories.isNotEmpty ? topCategories.first.value : 1;
        final topGoal = _controller.topGoal;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, ${_controller.userName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_formattedDate(DateTime.now()), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5A623), Color(0xFFE89A3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Disponible este mes', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_controller.generalBalance} MXN',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.arrow_upward, size: 14, color: Colors.black54),
                                SizedBox(width: 4),
                                Text('Ingresos', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            Text('\$${_controller.totalIncome}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.arrow_downward, size: 14, color: Colors.black54),
                                SizedBox(width: 4),
                                Text('Gastos', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            Text('\$${_controller.totalExpenses}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gastos por categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ExpenseView())),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text('Ver todo', style: TextStyle(color: Color(0xFFE89A3C), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (topCategories.isEmpty)
                const Text('Aún no tienes gastos registrados.', style: TextStyle(color: Colors.grey))
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: topCategories.map((entry) {
                      final ratio = maxCategoryAmount == 0 ? 0.0 : entry.value / maxCategoryAmount;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('\$${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                color: const Color(0xFFE89A3C),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Meta de ahorro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SavingsGoalView())),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text('Ver todas', style: TextStyle(color: Color(0xFFE89A3C), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (topGoal == null)
                const Text('Aún no tienes metas de ahorro.', style: TextStyle(color: Colors.grey))
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFE3F2E9), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(topGoal.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text('${(topGoal.progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: topGoal.progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.6),
                          color: const Color(0xFF1B6B4E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('\$${topGoal.currentAmount} de \$${topGoal.targetAmount}', style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
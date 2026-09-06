import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/reports_controller.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final ReportsController _controller = ReportsController();

  static const List<Color> _palette = [
    Color(0xFFE89A3C),
    Color(0xFF5B4FE0),
    Color(0xFF1B6B4E),
    Color(0xFFE0562D),
    Color(0xFF4B3F9E),
    Color(0xFF2E6B3E),
    Color(0xFF8B3A2B),
    Color(0xFF888888),
  ];

  Widget _sectionCard({required String title, required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryPie() {
    final data = _controller.categoryTotals;
    if (data.isEmpty) {
      return const Text('Aún no tienes gastos registrados para graficar.');
    }
    final entries = data.entries.toList();
    final total = data.values.fold(0, (sum, v) => sum + v);

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: List.generate(entries.length, (i) {
                  final percent = total == 0 ? 0 : (entries[i].value / total * 100);
                  return PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    title: '${percent.toStringAsFixed(0)}%',
                    color: _palette[i % _palette.length],
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, color: _palette[i % _palette.length]),
                      const SizedBox(width: 6),
                      Expanded(child: Text(entries[i].key, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseBar() {
    final income = _controller.totalIncome.toDouble();
    final expense = _controller.totalExpenses.toDouble();
    final maxY = (income > expense ? income : expense) * 1.2 + 1;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: income, color: Colors.green, width: 40, borderRadius: BorderRadius.circular(6))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: expense, color: Colors.red, width: 40, borderRadius: BorderRadius.circular(6))]),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value == 0 ? 'Ingreso' : 'Gasto', style: const TextStyle(fontSize: 12));
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildAdvancedLockedMessage() {
    final have = _controller.expenses.length;
    final need = ReportsController.minRecordsForAdvanced;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Llevas $have de $need gastos registrados. Con $need desbloqueas gráficas avanzadas '
              '(dispersión y proyecciones) personalizadas para tu tipo de ingreso.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedIncomeExtras() {
    return _sectionCard(
      title: 'Tu mes con ingreso fijo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progreso de ahorro'),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _controller.savingsProgressPercent,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.grey.withOpacity(0.3),
            color: const Color(0xFFE89A3C),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${_controller.daysRemainingInPeriod} días restantes para tu siguiente ingreso'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariableIncomeExtras() {
    final expenses = _controller.expensesSortedByDate;
    return _sectionCard(
      title: 'Tu gasto es variable',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cada punto es un gasto: en qué día del mes ocurrió (eje horizontal) y cuánto costó (eje vertical).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: expenses.map((e) {
                  return ScatterSpot(e.date.day.toDouble(), e.amount.toDouble());
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Presupuesto de seguridad sugerido: \$${_controller.suggestedSafetyBudget} MXN (20% de tu ingreso)'),
        ],
      ),
    );
  }

  Widget _buildMixedIncomeExtras() {
    final data = _controller.incomeSourceBreakdown;
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList();
    final maxY = (data.values.isEmpty ? 0 : data.values.reduce((a, b) => a > b ? a : b)).toDouble() * 1.2 + 1;

    return _sectionCard(
      title: 'Tus fuentes de ingreso',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: List.generate(entries.length, (i) {
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: entries[i].value.toDouble(), color: _palette[i % _palette.length], width: 30, borderRadius: BorderRadius.circular(6)),
              ]);
            }),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                    return Text(entries[i].key, style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget? _buildIncomeTypeExtras() {
    switch (_controller.effectiveIncomeType) {
      case 'Mesada':
      case 'Empleado':
        return _buildFixedIncomeExtras();
      case 'Freelance':
      case 'Negocio propio':
        return _buildVariableIncomeExtras();
      case 'Mixto':
        return _buildMixedIncomeExtras();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final extras = _buildIncomeTypeExtras();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Reportes'),
            elevation: 0,
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_controller.isLiquidityAtRisk)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tus gastos superan tu ingreso registrado. Mostrando solo lo esencial '
                                'para enfocarnos en liquidez y supervivencia.',
                                style: TextStyle(fontSize: 13, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _sectionCard(
                      title: _controller.isLiquidityAtRisk ? 'Gasto Vital por categoría' : 'Gasto por categoría',
                      child: _buildCategoryPie(),
                    ),
                    _sectionCard(title: 'Ingreso vs Gasto', child: _buildIncomeVsExpenseBar()),
                    if (extras != null) extras,
                  ],
                ),
        );
      },
    );
  }
}
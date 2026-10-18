import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/reports_controller.dart';
import '../services/reference_income_service.dart';

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

  Widget _legend(List<MapEntry<String, Color>> items) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: item.value),
                  const SizedBox(width: 4),
                  Text(item.key, style: const TextStyle(fontSize: 11)),
                ],
              ))
          .toList(),
    );
  }

  Widget _lockedMessage(String unlocks) {
    final have = _controller.totalExpenseRecords;
    const need = ReportsController.minRecordsForAdvanced;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Llevas $have de $need gastos registrados. Con $need se desbloquea $unlocks.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _cycleRangeText() {
    final c = _controller.currentCycle;
    if (c == null) return '';
    final last = c.end.subtract(const Duration(days: 1));
    return 'Ciclo actual: ${c.start.day}/${c.start.month} al ${last.day}/${last.month}';
  }

  // ---------- Gráficas básicas ----------

  Widget _buildCategoryPie() {
    final data = _controller.categoryTotals;
    if (data.isEmpty) {
      return const Text('Aún no tienes gastos registrados en este ciclo.');
    }
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = data.values.fold(0, (sum, v) => sum + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: List.generate(entries.length, (i) {
                final percent = total == 0 ? 0 : entries[i].value / total * 100;
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
        const SizedBox(height: 12),
        _legend([
          for (var i = 0; i < entries.length; i++) MapEntry('${entries[i].key} (\$${entries[i].value})', _palette[i % _palette.length]),
        ]),
      ],
    );
  }

  /// Mesada: porcentaje gastado por categoría respecto al ingreso fijo del ciclo.
  Widget _buildIncomeSharePie() {
    final income = _controller.cycleIncome;
    if (income <= 0) {
      return const Text('Registra tu ingreso de este ciclo para ver qué porcentaje llevas gastado.');
    }
    final data = _controller.categoryTotals;
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final remaining = _controller.cycleRemaining;
    final spentPercent = (_controller.cycleSpent / income * 100).toStringAsFixed(0);

    final sections = <PieChartSectionData>[
      for (var i = 0; i < entries.length; i++)
        PieChartSectionData(
          value: entries[i].value.toDouble(),
          title: '${(entries[i].value / income * 100).toStringAsFixed(0)}%',
          color: _palette[i % _palette.length],
          radius: 60,
          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      if (remaining > 0)
        PieChartSectionData(
          value: remaining.toDouble(),
          title: '${(remaining / income * 100).toStringAsFixed(0)}%',
          color: Colors.grey.shade400,
          radius: 60,
          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Llevas gastado el $spentPercent% de tu ingreso de este ciclo (\$${_controller.cycleSpent} de \$$income).',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (sections.isNotEmpty)
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 32, sections: sections)),
          ),
        const SizedBox(height: 12),
        _legend([
          for (var i = 0; i < entries.length; i++) MapEntry(entries[i].key, _palette[i % _palette.length]),
          if (remaining > 0) MapEntry('Sin gastar', Colors.grey.shade400),
        ]),
      ],
    );
  }

  Widget _buildIncomeVsExpenseBar() {
    final income = _controller.cycleIncome.toDouble();
    final expense = _controller.cycleSpent.toDouble();
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
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(value == 0 ? 'Ingreso' : 'Gasto', style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  // ---------- Reportes por perfil ----------

  /// Mesada: progreso de ahorro y días restantes para el siguiente ingreso.
  Widget _buildMesadaExtras() {
    return _sectionCard(
      title: 'Tu ciclo con ingreso fijo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En modo supervivencia se oculta lo relacionado con inversión (ahorro).
          if (!_controller.isLiquidityAtRisk) ...[
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
          ],
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('${_controller.daysRemainingInCycle} días restantes para tu siguiente ingreso'),
            ],
          ),
        ],
      ),
    );
  }

  /// Empleado: gasto promedio vs actual, con promedio móvil de 3 ciclos.
  Widget _buildEmpleadoExtras() {
    if (!_controller.hasEnoughRecordsForAdvanced) {
      return _sectionCard(
        title: 'Tu gasto: promedio vs actual',
        child: _lockedMessage('la comparación de tu gasto promedio contra el actual'),
      );
    }

    final points = _controller.spendingHistory;
    final average = _controller.averageSpentLastCycles;
    final current = _controller.cycleSpent;

    final summary = average == null
        ? 'Aún no tienes ciclos completos para calcular tu promedio.'
        : 'Promedio de tus últimos ciclos: \$${average.toStringAsFixed(0)}. Este ciclo llevas \$$current '
            '(${(current / (average == 0 ? 1 : average) * 100).toStringAsFixed(0)}% de tu promedio).';

    final spentSpots = [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].spent.toDouble())];
    final averageSpots = [
      for (var i = 0; i < points.length; i++)
        if (points[i].movingAverage != null) FlSpot(i.toDouble(), points[i].movingAverage!),
    ];

    return _sectionCard(
      title: 'Tu gasto: promedio vs actual',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          if (points.length >= 2)
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spentSpots,
                      color: const Color(0xFFE89A3C),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    if (averageSpots.isNotEmpty)
                      LineChartBarData(
                        spots: averageSpots,
                        color: const Color(0xFF5B4FE0),
                        barWidth: 2,
                        dashArray: [6, 4],
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (value != i.toDouble() || i < 0 || i >= points.length) return const SizedBox.shrink();
                          return Text(points[i].label, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _legend(const [
            MapEntry('Gasto por ciclo', Color(0xFFE89A3C)),
            MapEntry('Promedio móvil (3 ciclos)', Color(0xFF5B4FE0)),
          ]),
        ],
      ),
    );
  }

  String _referenceSourceLabel(ReferenceIncomeSource source) {
    switch (source) {
      case ReferenceIncomeSource.safetyBase:
        return 'tu Ingreso Base de Seguridad';
      case ReferenceIncomeSource.diagnosis:
        return 'el ingreso que declaraste en tu diagnóstico';
      case ReferenceIncomeSource.cycle:
        return 'tu ingreso de este ciclo';
    }
  }

  /// Freelance / Negocio propio: presupuesto de seguridad y dispersión.
  List<Widget> _buildVariableExtras() {
    final reference = _controller.referenceIncome;
    final base = _controller.safetyBase;

    final budgetText = (reference == null || base <= 0)
        ? 'Registra tus ingresos para calcular tu presupuesto de seguridad.'
        : 'Planea este ciclo con \$$base MXN (${_referenceSourceLabel(reference.source)}). '
            'Te sugerimos gastar como máximo \$${_controller.safetySpendingCap} MXN y reservar '
            '\$${_controller.safetyReserve} MXN (20%) como colchón para los meses con menos ingreso.';

    final expenses = _controller.scatterExpenses;

    return [
      _sectionCard(
        title: 'Presupuesto de seguridad',
        child: Text(budgetText, style: const TextStyle(fontSize: 13)),
      ),
      _sectionCard(
        title: 'Tu gasto es variable',
        child: !_controller.hasEnoughRecordsForAdvanced
            ? _lockedMessage('la gráfica de dispersión de tus gastos')
            : expenses.isEmpty
                ? const Text('Aún no hay gastos para graficar.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cada punto es un gasto de tus últimos ciclos: en qué día del mes ocurrió (eje horizontal) '
                        'y cuánto costó (eje vertical).',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ScatterChart(
                          ScatterChartData(
                            minX: 1,
                            maxX: 31,
                            minY: 0,
                            scatterSpots: expenses.map((e) => ScatterSpot(e.date.day.toDouble(), e.amount.toDouble())).toList(),
                            titlesData: const FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 5)),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: true),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    ];
  }

  /// Mixto: barras apiladas, una por periodo, un segmento por fuente.
  Widget _buildMixtoExtras() {
    final bars = _controller.incomeBySource;
    final types = <String>{for (final b in bars) ...b.amountByType.keys}.toList()..sort();
    final typeColors = {for (var i = 0; i < types.length; i++) types[i]: _palette[i % _palette.length]};
    final maxTotal = bars.isEmpty ? 0 : bars.map((b) => b.total).reduce((a, b) => a > b ? a : b);

    if (maxTotal == 0) {
      return _sectionCard(
        title: 'Tus ingresos por fuente',
        child: const Text('Aún no hay ingresos registrados por periodo.'),
      );
    }

    return _sectionCard(
      title: 'Tus ingresos por fuente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxTotal * 1.2,
                barGroups: List.generate(bars.length, (i) {
                  final bar = bars[i];
                  double from = 0;
                  final stack = <BarChartRodStackItem>[];
                  for (final type in types) {
                    final amount = (bar.amountByType[type] ?? 0).toDouble();
                    if (amount <= 0) continue;
                    stack.add(BarChartRodStackItem(from, from + amount, typeColors[type]!));
                    from += amount;
                  }
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: bar.total.toDouble(),
                      width: 22,
                      color: Colors.transparent,
                      rodStackItems: stack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]);
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                        return Text(bars[i].label, style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _legend([for (final t in types) MapEntry(t, typeColors[t]!)]),
        ],
      ),
    );
  }

  List<Widget> _buildProfileSections() {
    switch (_controller.effectiveIncomeType) {
      case 'Mesada':
        return [_buildMesadaExtras()];
      case 'Empleado':
        return [_buildEmpleadoExtras()];
      case 'Freelance':
      case 'Negocio propio':
        return _buildVariableExtras();
      case 'Mixto':
        return [_buildMixtoExtras()];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final isMesada = _controller.effectiveIncomeType == 'Mesada';
        final atRisk = _controller.isLiquidityAtRisk;

        return Scaffold(
          appBar: AppBar(title: const Text('Reportes'), elevation: 0),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_controller.currentCycle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_cycleRangeText(), style: const TextStyle(color: Colors.grey)),
                      ),
                    if (atRisk)
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
                                'Tus gastos de este ciclo superan tu ingreso. Mostramos solo lo esencial '
                                'para enfocarnos en tu liquidez.',
                                style: TextStyle(fontSize: 13, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isMesada)
                      _sectionCard(title: 'Tu ingreso gastado por categoría', child: _buildIncomeSharePie())
                    else
                      _sectionCard(
                        title: atRisk ? 'Gasto Vital por categoría' : 'Gasto por categoría',
                        child: _buildCategoryPie(),
                      ),
                    _sectionCard(title: 'Ingreso vs gasto', child: _buildIncomeVsExpenseBar()),
                    ..._buildProfileSections(),
                  ],
                ),
        );
      },
    );
  }
}
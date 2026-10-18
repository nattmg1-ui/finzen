import 'package:flutter/material.dart';
import '../controllers/recommendations_controller.dart';
import '../data/onboarding_recommendations.dart';
import '../services/reference_income_service.dart';
import '../services/tcm_service.dart';
import 'lesson_detail_view.dart';

class RecommendationsView extends StatefulWidget {
  const RecommendationsView({super.key});

  @override
  State<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends State<RecommendationsView> {
  final RecommendationsController _controller = RecommendationsController();

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

  Widget _lessonLink(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.article_outlined, size: 18, color: Color(0xFFE89A3C)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }

  /// Módulo 1: recomendaciones generales de los primeros 14 días.
  Widget? _buildOnboarding() {
    final onboarding = _controller.onboarding;
    final day = _controller.onboardingDay;
    if (onboarding == null || day == null) return null;

    return _sectionCard(
      title: 'Recomendaciones para empezar (día $day de $onboardingDays)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(onboarding.message, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          const Text('Lecciones para ti', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(height: 4),
          ...onboarding.lessons.map(
            (lesson) => _lessonLink(
              lesson.title,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => LessonDetailView(lesson: lesson))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBanner() {
    final mode = _controller.financialMode;
    if (mode == null) return const SizedBox.shrink();

    if (mode.isContingencyMode) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Modo de contingencia activo: no registraste ingresos en este ciclo. '
                'Pausamos las comparaciones históricas y nos enfocamos en ayudarte a reducir gastos esenciales.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (mode.isStabilityMode) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.health_and_safety_outlined, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tus gastos esenciales superan tu ingreso disponible este ciclo. Pausamos las alertas '
                'de ahorro de la regla 50/30/20 para enfocarnos en tu estabilidad financiera.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCuboBar() {
    final aggregate = _controller.currentCycleAggregate;
    if (aggregate == null || aggregate.total == 0) {
      return const Text('Aún no hay gastos ni aportes registrados en el ciclo actual.');
    }

    final total = aggregate.total;
    final vitalPct = aggregate.cuboA / total;
    final opcionalPct = aggregate.cuboB / total;
    final futuroPct = aggregate.cuboC / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (vitalPct > 0) Expanded(flex: (vitalPct * 1000).round(), child: Container(color: const Color(0xFF1B6B4E))),
                if (opcionalPct > 0) Expanded(flex: (opcionalPct * 1000).round(), child: Container(color: const Color(0xFFE0562D))),
                if (futuroPct > 0) Expanded(flex: (futuroPct * 1000).round(), child: Container(color: const Color(0xFF5B4FE0))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendDot('Vital', '${(vitalPct * 100).round()}%', const Color(0xFF1B6B4E)),
            _legendDot('Opcional', '${(opcionalPct * 100).round()}%', const Color(0xFFE0562D)),
            _legendDot('Futuro', '${(futuroPct * 100).round()}%', const Color(0xFF5B4FE0)),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($value)', style: const TextStyle(fontSize: 13)),
      ],
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

  Widget _buildProjection() {
    final result = _controller.smoothingResult;
    if (result == null) {
      return const Text('Sin datos suficientes todavía.');
    }

    final amount = result.projection.toStringAsFixed(0);
    final mainText = result.isCalibrating
        ? 'Tu primer ciclo todavía no termina. Por ahora, tu gasto estimado para este ciclo es de \$$amount MXN, '
            'según lo que declaraste en tu diagnóstico.'
        : 'Se espera que termines este ciclo gastando alrededor de \$$amount MXN, según tu patrón reciente de gasto.';

    final reference = _controller.referenceIncome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mainText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        if (_controller.projectionExceedsIncome && reference != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta proyección supera ${_referenceSourceLabel(reference.source)} '
                    '(\$${reference.amount} MXN). Revisa tus gastos para no quedarte corto.',
                    style: const TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSafetyBaseIncome() {
    final ibs = _controller.safetyBaseIncome;
    if (ibs == null) return const SizedBox.shrink();
    return _sectionCard(
      title: 'Ingreso Base de Seguridad',
      child: Text(
        'Para planear tu presupuesto con un ingreso variable, usa \$$ibs MXN como referencia: '
        'es el ingreso más bajo que registraste en tus últimos 3 ciclos.',
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildPareto() {
    final pareto = _controller.paretoResult;
    if (pareto == null) {
      return const Text('Necesitas al menos 2 categorías de gasto Opcional este ciclo para este análisis.');
    }

    final priority = pareto.priorityCategories;
    final names = priority.map((c) => c.category).join(', ');
    final cumulative = pareto.priorityCumulativePercentage.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${priority.length} ${priority.length == 1 ? 'categoría concentra' : 'categorías concentran'} '
          'el $cumulative% de tu gasto opcional:',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(names, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        ...pareto.categories.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c.category, style: TextStyle(fontSize: 12, fontWeight: c.isPriority ? FontWeight.bold : FontWeight.normal)),
                  Text('\$${c.amount} (${c.percentage.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTcm(TcmResult tcm) {
    final percent = (tcm.tcm * 100).toStringAsFixed(1);

    if (tcm.exceedsThreshold) {
      return Text(
        'Tu ingreso subió \$${tcm.incomeDelta} respecto al ciclo anterior, y destinaste el $percent% de ese '
        'aumento a gasto opcional en vez de ahorrarlo. Considera aportar esa diferencia a una meta de ahorro.',
        style: const TextStyle(fontSize: 13),
      );
    }

    return Text(
      'Tu ingreso subió \$${tcm.incomeDelta} respecto al ciclo anterior, y destinaste el $percent% de ese '
      'aumento a gasto opcional. Vas por buen camino.',
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildHistoryLockedMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.blueGrey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Necesitas al menos 3 ciclos completos de historial para desbloquear la detección '
              'de anomalías y de gasto impulsivo.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalies() {
    final anomalies = _controller.anomalies;
    if (anomalies.isEmpty) {
      return const Text('No se detectaron gastos fuera de lo normal este ciclo.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: anomalies.map((a) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${a.category}: gastaste \$${a.currentSpend} este ciclo (tu promedio ponderado es \$${a.wma.toStringAsFixed(0)})',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImpulsive() {
    final impulsive = _controller.impulsiveCategories;
    if (impulsive.isEmpty) {
      return const Text('Tus categorías de gasto se mantienen estables entre ciclos.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: impulsive.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.shuffle, size: 18, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tus gastos en ${c.category} varían mucho entre ciclos (variabilidad de ${c.cv.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget? _buildEducationSuggestion() {
    final lesson = _controller.suggestedLesson;
    final challenge = _controller.challengeSuggestion;
    if (lesson == null && challenge == null) return null;

    return _sectionCard(
      title: 'Para ti',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (challenge != null) ...[
            const Text('Reto sugerido', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 6),
            Text(challenge, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
          ],
          if (lesson != null) ...[
            const Text('Lección recomendada', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 2),
            _lessonLink(
              lesson.title,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => LessonDetailView(lesson: lesson))),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final mode = _controller.financialMode;
        final showHistoricalSections = mode == null || !mode.isContingencyMode;
        final onboardingCard = _buildOnboarding();
        final educationSuggestion = _buildEducationSuggestion();
        final tcm = _controller.tcmResult;

        return Scaffold(
          appBar: AppBar(title: const Text('Recomendaciones'), elevation: 0),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildModeBanner(),
                    if (onboardingCard != null) onboardingCard,
                    _sectionCard(title: 'Cómo se reparte tu gasto', child: _buildCuboBar()),
                    _sectionCard(title: 'Proyección de gasto para este ciclo', child: _buildProjection()),
                    _buildSafetyBaseIncome(),
                    if (educationSuggestion != null) educationSuggestion,
                    if (showHistoricalSections) ...[
                      _sectionCard(title: 'Análisis Pareto', child: _buildPareto()),
                      if (tcm != null) _sectionCard(title: 'Tasa de Consumo Marginal', child: _buildTcm(tcm)),
                      if (!_controller.hasEnoughHistory)
                        _buildHistoryLockedMessage()
                      else ...[
                        _sectionCard(title: 'Gasto arriba de lo normal', child: _buildAnomalies()),
                        _sectionCard(title: 'Detección de impulso', child: _buildImpulsive()),
                      ],
                    ],
                  ],
                ),
        );
      },
    );
  }
}
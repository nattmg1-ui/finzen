import '../models/lesson_model.dart';
import 'lessons_data.dart';

/// Recomendación general de los primeros 14 días de uso (Módulo 1, Anexo A).
class OnboardingRecommendation {
  final String message;
  final List<LessonModel> lessons;

  OnboardingRecommendation({required this.message, required this.lessons});
}

/// Duración del periodo de recomendaciones generales.
const int onboardingDays = 14;

/// Anexo A: lecciones por objetivo financiero del diagnóstico.
const Map<String, List<String>> _lessonIdsByGoal = {
  'Ahorrar': ['interes-compuesto', 'fondo-emergencia'],
  'Reducir gastos': ['fijos-vs-variables', 'gastos-hormiga'],
  'Liquidar deudas': ['salir-deuda-tarjeta', 'bola-nieve-avalancha'],
  'Cumplir objetivos': ['regla-50-30-20', 'presupuesto-mensual'],
};

const Map<String, String> _messageByGoal = {
  'Ahorrar': 'Tu objetivo es ahorrar. Aparta una cantidad fija en cuanto recibas tu ingreso, aunque sea pequeña, '
      'y construye poco a poco un fondo de emergencia.',
  'Reducir gastos': 'Tu objetivo es reducir gastos. Registra todos tus gastos estos días, incluso los pequeños: '
      'así vas a ver en qué se te va el dinero y dónde puedes recortar.',
  'Liquidar deudas': 'Tu objetivo es liquidar deudas. Paga más del mínimo siempre que puedas y elige un orden '
      'para atacar tus deudas, en vez de repartir pagos pequeños entre todas.',
  'Cumplir objetivos': 'Tu objetivo es cumplir tus metas. Arma un presupuesto sencillo y separa desde el inicio '
      'del ciclo lo que vas a destinar a cada meta.',
};

const String _neverSavesMessage = 'Nos dijiste que nunca ahorras. Antes que nada, conoce la regla 50/30/20: '
    'es la base para repartir tu dinero entre necesidades, deseos y ahorro.';

/// Arma la recomendación según las respuestas del diagnóstico. Si el
/// hábito de ahorro es "Nunca", la regla 50/30/20 va primero sin
/// importar el objetivo. Devuelve null si no hay datos de diagnóstico.
OnboardingRecommendation? buildOnboardingRecommendation({
  String? financialGoal,
  String? savingHabit,
}) {
  final lessonIds = <String>[];
  final messages = <String>[];

  if (savingHabit == 'Nunca') {
    lessonIds.add('regla-50-30-20');
    messages.add(_neverSavesMessage);
  }

  final goalLessonIds = _lessonIdsByGoal[financialGoal];
  if (goalLessonIds != null) {
    for (final id in goalLessonIds) {
      if (!lessonIds.contains(id)) lessonIds.add(id);
    }
    messages.add(_messageByGoal[financialGoal]!);
  }

  if (lessonIds.isEmpty) return null;

  final lessons = lessonIds.map((id) => allLessons.firstWhere((l) => l.id == id)).toList();
  return OnboardingRecommendation(message: messages.join('\n\n'), lessons: lessons);
}
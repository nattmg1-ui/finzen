import '../models/lesson_model.dart';
import 'lessons_data.dart';

/// Una recomendación general de los primeros 14 días (Módulo 1, Anexo A):
/// un consejo corto ligado a una lección del Módulo 9.
class OnboardingRecommendation {
  /// Identificador único de la recomendación (por ejemplo 'ahorrar-03').
  /// Varias recomendaciones pueden apuntar a la misma lección.
  final String id;
  final LessonModel lesson;
  final String message;

  OnboardingRecommendation({required this.id, required this.lesson, required this.message});
}

/// Duración del periodo de recomendaciones generales.
const int onboardingDays = 14;

class _Entry {
  final String lessonId;
  final String message;

  const _Entry(this.lessonId, this.message);
}

/// Prefijo del id de cada recomendación según el objetivo.
const Map<String, String> _idPrefixByGoal = {
  'Ahorrar': 'ahorrar',
  'Reducir gastos': 'reducir',
  'Liquidar deudas': 'deudas',
  'Cumplir objetivos': 'objetivos',
};

/// Anexo A: 14 recomendaciones por objetivo financiero, en orden.
const Map<String, List<_Entry>> _entriesByGoal = {
  'Ahorrar': [
    _Entry('interes-compuesto',
        'Ahorrar desde hoy, aunque sea poco, rinde más que ahorrar mucho después. Esta lección te explica por qué.'),
    _Entry('fondo-emergencia',
        'Antes de cualquier otra meta, junta un colchón para imprevistos. Aparta una cantidad fija en cuanto recibas tu ingreso.'),
    _Entry('regla-50-30-20',
        'Una referencia sencilla para empezar: intenta que el 20% de tu ingreso vaya a ahorro. Si hoy no llegas, empieza con menos y sube poco a poco.'),
    _Entry('fondo-emergencia',
        'Ponle una primera meta pequeña a tu fondo de emergencia, por ejemplo un mes de tus gastos básicos. Créala en Metas como tipo Vital.'),
    _Entry('interes-compuesto',
        'El tiempo pesa más que el monto. Un aporte pequeño y constante cada ciclo suele ganarle a un aporte grande que nunca llega.'),
    _Entry('presupuesto-mensual',
        'Ahorra primero y gasta después: separa tu ahorro el mismo día que recibes tu ingreso, no con lo que sobre al final.'),
    _Entry('gastos-hormiga',
        'Revisa tus gastos pequeños de esta semana. Lo que sumen puede convertirse en un aporte extra para tus metas.'),
    _Entry('fondo-emergencia',
        'Guarda tu fondo de emergencia aparte de tu dinero del día a día, para que no se mezcle ni se gaste sin querer.'),
    _Entry('fijos-vs-variables',
        'Tus gastos variables son donde más margen hay para ahorrar. Elige uno y ponle un límite este ciclo.'),
    _Entry('regla-50-30-20',
        'Si tu gasto en deseos pasa del 30%, esa diferencia es dinero que podría ir a tu ahorro. Revisa cómo se reparte tu gasto en Recomendaciones.'),
    _Entry('interes-compuesto',
        'Cuando recibas un dinero extra, como un bono o un ingreso inesperado, aparta una parte para tus metas antes de gastarlo.'),
    _Entry('presupuesto-mensual',
        'Revisa tu presupuesto una vez por semana, no solo al final del ciclo. Así corriges a tiempo y proteges lo que ibas a ahorrar.'),
    _Entry('errores-tarjeta',
        'Las compras a crédito que no puedes pagar completas generan intereses que se comen tu ahorro. Úsala solo para lo que puedas liquidar ese mes.'),
    _Entry('fondo-emergencia',
        'Usa tu fondo solo para imprevistos reales: perder tu ingreso, una reparación urgente o un gasto médico. No es para vacaciones ni ofertas.'),
  ],
  'Reducir gastos': [
    _Entry('fijos-vs-variables',
        'Para reducir gastos, primero sepáralos: los fijos se negocian una vez y los variables se controlan día a día.'),
    _Entry('gastos-hormiga',
        'Registra todos tus gastos estos días, incluso los pequeños. Así vas a ver en qué se te va el dinero sin darte cuenta.'),
    _Entry('fijos-vs-variables',
        'Haz una lista de tus gastos fijos: es el mínimo que necesitas cubrir cada ciclo antes de pensar en cualquier otra cosa.'),
    _Entry('gastos-hormiga',
        'Elige una subcategoría con muchos movimientos pequeños, como cafeterías o delivery, y suma cuánto llevas este ciclo.'),
    _Entry('regla-50-30-20',
        'Revisa cuánto de tu gasto se va a deseos. Si pasa del 30%, ahí tienes el primer lugar para recortar.'),
    _Entry('presupuesto-mensual',
        'Ponle un límite a cada categoría variable al inicio del ciclo y compáralo con lo que llevas gastado cada semana.'),
    _Entry('fijos-vs-variables',
        'Revisa tus suscripciones digitales. Cancela las que no usaste en el último mes: es un gasto fijo que se recorta una sola vez.'),
    _Entry('gastos-hormiga',
        'No se trata de eliminar todos tus gustos, sino de decidir cuáles valen la pena. Quédate con los que de verdad disfrutas.'),
    _Entry('presupuesto-mensual',
        'Usa tus números reales de los últimos ciclos para fijar tus límites. Un presupuesto "ideal" que no se parece a cómo gastas se abandona rápido.'),
    _Entry('fijos-vs-variables',
        'Cuando un ciclo se complique, ajusta primero los gastos variables antes de tocar compromisos como la renta o la colegiatura.'),
    _Entry('gastos-hormiga',
        'Antes de una compra pequeña que no tenías planeada, espera un día. Muchas veces las ganas se pasan.'),
    _Entry('regla-50-30-20',
        'Durante este ciclo, clasifica cada gasto como necesidad o deseo antes de pagarlo. Solo notarlo ya cambia cómo gastas.'),
    _Entry('errores-tarjeta',
        'Revisa tu estado de cuenta con calma: cargos duplicados, comisiones o anualidades olvidadas también son gastos que puedes eliminar.'),
    _Entry('presupuesto-mensual',
        'Lo que logres recortar no lo dejes suelto: pásalo a una meta de ahorro para que no se vaya en otro gasto.'),
  ],
  'Liquidar deudas': [
    _Entry('salir-deuda-tarjeta',
        'Paga más del mínimo siempre que puedas. Esta lección te explica cómo salir de la deuda de tu tarjeta.'),
    _Entry('bola-nieve-avalancha',
        'Elige un orden para atacar tus deudas en vez de repartir pagos pequeños entre todas.'),
    _Entry('salir-deuda-tarjeta',
        'Haz una lista de todas tus deudas con su saldo, su tasa de interés y su pago mínimo. No puedes ordenar lo que no tienes a la vista.'),
    _Entry('bola-nieve-avalancha',
        'Si te importa pagar menos intereses, empieza por la deuda con la tasa más alta: es el método avalancha.'),
    _Entry('bola-nieve-avalancha',
        'Si necesitas ver avances rápido para no rendirte, empieza por la deuda más pequeña: es el método bola de nieve.'),
    _Entry('errores-tarjeta',
        'Pagar solo el mínimo hace que la mayor parte de tu pago se vaya en intereses y que la deuda casi no baje.'),
    _Entry('cat-tarjetas',
        'Revisa el CAT de cada crédito que tienes. Te dice cuánto te cuesta de verdad cada uno, con comisiones incluidas.'),
    _Entry('errores-tarjeta',
        'Mientras pagas tu deuda, evita usar la tarjeta para compras que no puedas liquidar ese mismo mes.'),
    _Entry('presupuesto-mensual',
        'Incluye el pago de tus deudas en tu presupuesto como un gasto fijo, no como lo que sobre al final.'),
    _Entry('gastos-hormiga',
        'Junta lo que gastas en compras pequeñas durante una semana y destínalo a un pago extra de tu deuda.'),
    _Entry('bola-nieve-avalancha',
        'Cuando termines de pagar una deuda, suma ese pago a la siguiente de tu lista. Así el avance se acelera.'),
    _Entry('cat-tarjetas',
        'Antes de sacar una tarjeta o un crédito nuevo, compara el CAT y no solo la promoción o la tasa más visible.'),
    _Entry('fondo-emergencia',
        'Junta un fondo pequeño para imprevistos aunque sigas pagando deudas. Así un gasto inesperado no te obliga a volver a usar la tarjeta.'),
    _Entry('regla-50-30-20',
        'En la regla 50/30/20, el 20% puede ir a pagar deudas. Úsalo como referencia para decidir cuánto destinar cada ciclo.'),
  ],
  'Cumplir objetivos': [
    _Entry('regla-50-30-20',
        'Para cumplir tus metas, primero define cuánto de tu ingreso va a cada cosa. La regla 50/30/20 es un buen punto de partida.'),
    _Entry('presupuesto-mensual',
        'Arma un presupuesto sencillo y separa desde el inicio del ciclo lo que vas a destinar a cada meta.'),
    _Entry('presupuesto-mensual',
        'Escribe tus metas con un monto y una fecha concretos. "Ahorrar para un viaje" se cumple menos que "\$12,000 para diciembre".'),
    _Entry('regla-50-30-20',
        'Ponle prioridad a tus metas: no todas pueden avanzar igual de rápido. Decide cuál es la más importante para ti.'),
    _Entry('fondo-emergencia',
        'Antes de metas grandes, junta un pequeño fondo de emergencia. Así un imprevisto no te obliga a usar lo que ya ahorraste.'),
    _Entry('interes-compuesto',
        'Aportar poco pero seguido funciona mejor que esperar a tener mucho. Haz un aporte a tu meta cada vez que recibas tu ingreso.'),
    _Entry('gastos-hormiga',
        'Calcula cuánto gastas en compras pequeñas en un ciclo: puede ser justo lo que le falta a tu meta para avanzar.'),
    _Entry('presupuesto-mensual',
        'Revisa el avance de tus metas una vez por semana. Ver el progreso ayuda a mantener la constancia.'),
    _Entry('fijos-vs-variables',
        'Si una meta no avanza, busca margen en tus gastos variables antes de cambiar la fecha límite.'),
    _Entry('regla-50-30-20',
        'Una meta que pide más del 20% de tu ingreso puede poner en riesgo tus gastos básicos. Por eso la app te sugiere ajustar la fecha.'),
    _Entry('interes-compuesto',
        'Cuando recibas un ingreso extra, aparta una parte para tu meta prioritaria antes de decidir en qué gastar el resto.'),
    _Entry('errores-tarjeta',
        'Evita financiar tus metas con la tarjeta de crédito: los intereses pueden hacer que termines pagando mucho más.'),
    _Entry('presupuesto-mensual',
        'Celebra cuando llegues a la mitad de una meta, y usa ese impulso para ponerte la siguiente.'),
    _Entry('regla-50-30-20',
        'Al cerrar el ciclo, revisa cómo se repartió tu gasto en Recomendaciones y ajusta lo que vas a destinar a tus metas el siguiente.'),
  ],
};

/// Recomendación que va primero cuando el hábito de ahorro es "Nunca".
const _Entry _neverSavesEntry = _Entry(
  'regla-50-30-20',
  'Nos dijiste que nunca ahorras. Empieza por aquí: la regla 50/30/20 es la base para repartir tu dinero '
      'entre necesidades, deseos y ahorro.',
);

LessonModel _lessonById(String id) => allLessons.firstWhere((l) => l.id == id);

/// Lista ordenada de recomendaciones según el diagnóstico (máximo 14).
/// Si el hábito de ahorro es "Nunca", la recomendación de la regla
/// 50/30/20 va primero y después siguen las del objetivo; si la primera
/// del objetivo también es la regla 50/30/20, se omite para no repetirla.
/// Devuelve una lista vacía si no hay datos de diagnóstico.
List<OnboardingRecommendation> buildOnboardingCatalog({
  String? financialGoal,
  String? savingHabit,
}) {
  final entries = _entriesByGoal[financialGoal] ?? const <_Entry>[];
  final prefix = _idPrefixByGoal[financialGoal] ?? '';

  var goalRecommendations = <OnboardingRecommendation>[
    for (var i = 0; i < entries.length; i++)
      OnboardingRecommendation(
        id: '$prefix-${(i + 1).toString().padLeft(2, '0')}',
        lesson: _lessonById(entries[i].lessonId),
        message: entries[i].message,
      ),
  ];

  final catalog = <OnboardingRecommendation>[];

  if (savingHabit == 'Nunca') {
    catalog.add(OnboardingRecommendation(
      id: 'nunca-01',
      lesson: _lessonById(_neverSavesEntry.lessonId),
      message: _neverSavesEntry.message,
    ));
    if (goalRecommendations.isNotEmpty && goalRecommendations.first.lesson.id == _neverSavesEntry.lessonId) {
      goalRecommendations = goalRecommendations.skip(1).toList();
    }
  }

  catalog.addAll(goalRecommendations);
  return catalog.take(onboardingDays).toList();
}

/// Cuántas recomendaciones nuevas mostrar hoy: normalmente una, pero si
/// quedan más pendientes que días restantes (contando hoy), las
/// necesarias para que todas se muestren antes del día 14.
int onboardingCountForToday({required int pending, required int daysLeft}) {
  if (pending <= 0) return 0;
  if (daysLeft <= 1) return pending;
  return (pending / daysLeft).ceil();
}

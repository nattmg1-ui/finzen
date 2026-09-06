import '../models/lesson_model.dart';

/// Catálogo de contenido educativo del Módulo 9. Cubre los 5 temas
/// que pide el documento: presupuesto, ahorro, deudas, tarjetas, y
/// gastos fijos vs. variables. Todo el texto es contenido original.
const List<LessonModel> allLessons = [
  LessonModel(
    id: 'regla-50-30-20',
    title: 'Qué es la regla 50/30/20 y cómo aplicarla',
    category: 'Presupuesto',
    type: 'Artículo',
    summary: 'Una forma simple de repartir tu dinero en tres partes.',
    body:
        'La regla 50/30/20 propone dividir tu ingreso mensual en tres partes: 50% para necesidades '
        'básicas (renta, comida, transporte, servicios), 30% para deseos (entretenimiento, salidas, '
        'compras no esenciales), y 20% para ahorro o pago de deudas.\n\n'
        'No es una regla rígida: si vives en una ciudad cara o tienes deudas importantes, tus '
        'porcentajes reales pueden verse distintos. Lo valioso de este método no es cumplirlo al '
        'pie de la letra, sino tener una referencia clara para notar cuándo el gasto discrecional '
        'se está comiendo el espacio que deberías destinar a tus metas.\n\n'
        'Una forma práctica de empezar: durante un mes, clasifica cada gasto en una de las tres '
        'categorías sin cambiar tus hábitos todavía. Al final del mes vas a tener un diagnóstico '
        'real de en qué se te va el dinero, y desde ahí es mucho más fácil decidir qué ajustar.',
  ),
  LessonModel(
    id: 'presupuesto-mensual',
    title: 'Cómo armar un presupuesto mensual sin complicarte',
    category: 'Presupuesto',
    type: 'Mini-lección',
    summary: 'Los pasos mínimos para tener un presupuesto que sí uses.',
    body:
        'Un presupuesto no tiene que ser una hoja de cálculo complicada. Los tres pasos esenciales '
        'son: (1) saber cuánto entra, sumando todos tus ingresos del mes; (2) saber cuánto sale, '
        'registrando tus gastos por categoría; y (3) comparar ambos números para ver si te alcanza, '
        'te sobra, o te falta.\n\n'
        'El error más común es hacer un presupuesto "ideal" que no se parece a cómo realmente '
        'gastas, y abandonarlo a la primera semana. Es mejor empezar con tus números reales de los '
        'últimos meses y ajustar poco a poco, en vez de imponerte de golpe un plan perfecto.\n\n'
        'Revisar tu presupuesto una vez por semana (no solo al final del mes) te da margen para '
        'corregir a tiempo si un gasto se está saliendo de control, en vez de descubrirlo cuando ya '
        'no hay nada que hacer.',
  ),
  LessonModel(
    id: 'interes-compuesto',
    title: 'El interés compuesto explicado en 5 pasos',
    category: 'Ahorro',
    type: 'Infografía',
    summary: 'Por qué empezar a ahorrar antes importa más que cuánto ahorras.',
    body:
        '1. El interés compuesto es cuando ganas intereses no solo sobre tu dinero original, sino '
        'también sobre los intereses que ya generaste antes.\n\n'
        '2. Esto hace que el crecimiento no sea una línea recta, sino una curva que se acelera con '
        'el tiempo.\n\n'
        '3. Por eso, dos personas que ahorran la misma cantidad total pueden terminar con montos muy '
        'distintos si una empezó años antes que la otra.\n\n'
        '4. El tiempo dentro del mercado (o de la cuenta de ahorro) suele importar más que el monto '
        'exacto que se aporta cada mes.\n\n'
        '5. La conclusión práctica: empezar a ahorrar una cantidad pequeña hoy casi siempre le gana, '
        'a largo plazo, a esperar a "tener más dinero" para empezar en el futuro.',
  ),
  LessonModel(
    id: 'fondo-emergencia',
    title: 'Cómo crear un fondo de emergencia desde cero',
    category: 'Ahorro',
    type: 'Artículo',
    summary: 'Tu colchón contra imprevistos, explicado paso a paso.',
    body:
        'Un fondo de emergencia es dinero apartado exclusivamente para imprevistos reales: perder tu '
        'ingreso, una reparación urgente, un gasto médico. No es para vacaciones ni para "aprovechar '
        'una oferta".\n\n'
        'Una meta común es acumular entre 3 y 6 meses de tus gastos básicos, pero llegar directo a '
        'esa cifra puede sentirse imposible si estás empezando. Es más realista fijar una primera '
        'meta pequeña (por ejemplo, un mes de gastos básicos) y after eso, seguir creciendo el fondo '
        'poco a poco.\n\n'
        'Guardarlo en una cuenta separada de tu dinero del día a día ayuda a que no se mezcle con tus '
        'gastos normales ni se gaste "sin querer". Lo importante es que sea fácil de retirar cuando '
        'de verdad lo necesites, pero no tan a la mano que lo uses para cualquier cosa.',
  ),
  LessonModel(
    id: 'salir-deuda-tarjeta',
    title: 'Cómo salir de una deuda de tarjeta de crédito',
    category: 'Deudas',
    type: 'Mini-lección',
    summary: 'Estrategias prácticas para pagar el saldo de tu tarjeta.',
    body:
        'El interés de una tarjeta de crédito suele ser de los más altos entre los créditos '
        'disponibles, así que salir de esa deuda primero casi siempre conviene antes que otros '
        'objetivos financieros.\n\n'
        'Pagar solo el mínimo cada mes puede alargar la deuda por años y multiplicar lo que terminas '
        'pagando en intereses. Cuando sea posible, pagar más del mínimo (aunque sea un poco más) '
        'reduce ese costo de forma importante.\n\n'
        'Si tienes varias deudas a la vez, ordenarlas te ayuda a decidir por cuál empezar — ya sea '
        'por la tasa de interés más alta, o por el saldo más pequeño para ganar impulso (ver la '
        'siguiente lección sobre bola de nieve vs avalancha).',
  ),
  LessonModel(
    id: 'bola-nieve-avalancha',
    title: 'Bola de nieve vs avalancha: dos formas de pagar deudas',
    category: 'Deudas',
    type: 'Artículo',
    summary: 'Dos estrategias distintas para ordenar tus pagos.',
    body:
        'El método "avalancha" ordena tus deudas de mayor a menor tasa de interés, y destina el '
        'dinero extra a pagar primero la más cara. Matemáticamente, es la forma que menos intereses '
        'totales te hace pagar.\n\n'
        'El método "bola de nieve" ordena tus deudas de menor a mayor saldo, sin importar la tasa de '
        'interés, y ataca primero la más pequeña. No es la opción más barata en números, pero '
        'liquidar una deuda completa rápido genera una sensación de progreso que ayuda a mantener la '
        'motivación.\n\n'
        'Ninguna es "la correcta" para todos: si el costo total te importa más, avalancha suele '
        'ganar; si necesitas ver resultados rápido para no rendirte, bola de nieve puede funcionar '
        'mejor para ti.',
  ),
  LessonModel(
    id: 'cat-tarjetas',
    title: 'Cómo funciona el CAT y por qué importa',
    category: 'Tarjetas',
    type: 'Artículo',
    summary: 'El número que de verdad te dice cuánto cuesta un crédito.',
    body:
        'El CAT (Costo Anual Total) es un indicador que junta la tasa de interés de un crédito con '
        'otros costos asociados (comisiones, seguros, anualidades) en un solo número, expresado como '
        'porcentaje anual.\n\n'
        'Comparar solo la tasa de interés entre dos tarjetas puede ser engañoso si una tiene '
        'comisiones altas que la otra no tiene. El CAT permite comparar el costo real de dos '
        'productos financieros de forma más justa.\n\n'
        'En México, las instituciones financieras están obligadas a mostrar el CAT de sus productos '
        'de crédito, así que vale la pena buscarlo antes de sacar una tarjeta nueva, en vez de fijarte '
        'solo en promociones o en la tasa de interés que aparece más grande en la publicidad.',
  ),
  LessonModel(
    id: 'errores-tarjeta',
    title: 'Errores comunes al usar tu tarjeta de crédito',
    category: 'Tarjetas',
    type: 'Mini-lección',
    summary: 'Hábitos que hacen que una tarjeta salga más cara de lo necesario.',
    body:
        'Pagar solo el mínimo mes tras mes es uno de los errores más comunes: aunque parece manejable, '
        'hace que la deuda casi no baje y que la mayoría de tu pago se vaya en intereses.\n\n'
        'Usar la tarjeta para gastos que ya sabes que no vas a poder pagar completos ese mes '
        'convierte compras normales en deuda cara sin darte cuenta.\n\n'
        'No revisar tu estado de cuenta a detalle también es un error frecuente — cargos '
        'duplicados, comisiones inesperadas o anualidades que no recordabas pueden pasar '
        'desapercibidos si nunca lo revisas con calma.',
  ),
  LessonModel(
    id: 'fijos-vs-variables',
    title: 'Gastos fijos vs variables: la diferencia que cambia tu presupuesto',
    category: 'Gastos fijos y variables',
    type: 'Artículo',
    summary: 'Por qué separar estos dos tipos de gasto te da más control.',
    body:
        'Los gastos fijos son los que se repiten con el mismo monto (o casi) cada periodo: renta, '
        'suscripciones, colegiaturas. Los gastos variables cambian de un mes a otro: comida, '
        'transporte, entretenimiento.\n\n'
        'Conocer tus gastos fijos te dice el "piso" mínimo que necesitas cubrir sí o sí cada mes, '
        'antes de pensar en cualquier otra cosa. Los gastos variables, en cambio, son donde '
        'normalmente hay más margen para ajustar si necesitas liberar dinero.\n\n'
        'Cuando un mes se complica financieramente, revisar primero los gastos variables (en vez de '
        'tocar los fijos) suele ser el camino más rápido para encontrar dinero extra sin '
        'comprometer compromisos importantes como la renta o las colegiaturas.',
  ),
  LessonModel(
    id: 'gastos-hormiga',
    title: 'Cómo identificar gastos hormiga en tu día a día',
    category: 'Gastos fijos y variables',
    type: 'Mini-lección',
    summary: 'Los gastos pequeños que, sumados, pesan más de lo que parece.',
    body:
        'Los "gastos hormiga" son compras pequeñas y frecuentes que, vistas una por una, parecen '
        'insignificantes: un café, una app, una comida rápida. El problema no es el gasto individual, '
        'sino la suma acumulada a lo largo del mes.\n\n'
        'Una forma de detectarlos es revisar tus gastos por categoría (como los que ya registras en '
        'la app) y fijarte en las subcategorías donde tienes muchos movimientos pequeños, en vez de '
        'buscar un solo gasto grande.\n\n'
        'No se trata de eliminar por completo estos gastos —muchos son parte de disfrutar tu día a '
        'día— sino de tener claridad sobre cuánto representan en total, para decidir de forma '
        'consciente si ese monto sigue teniendo sentido para ti.',
  ),
];
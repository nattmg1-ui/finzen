/// Catálogo cerrado de categorías y subcategorías de gasto,
/// copiado textualmente del documento de Propuesta (Módulo 4).
///
/// La clasificación Vital/Opcional sigue la regla 50/30/20 descrita
/// en el Módulo 8 (Cubo A = Vital = necesidades fijas,
/// Cubo B = Opcional = deseos/entretenimiento). El usuario NUNCA
/// elige esto: se calcula solo a partir de la subcategoría elegida.
const Map<String, List<String>> expenseCategories = {
  'Alimentación': [
    'Supermercado / despensa',
    'Restaurantes y comida rápida',
    'Cafeterías y bebidas',
    'Comida a domicilio (delivery)',
  ],
  'Transporte': [
    'Transporte público (camión, metro, Uber)',
    'Gasolina',
    'Estacionamiento',
    'Mantenimiento de vehículo',
  ],
  'Entretenimiento y salidas': [
    'Cine, conciertos y eventos',
    'Bares y antros',
    'Gaming / In-game purchases',
    'Videojuegos y suscripciones de streaming',
    'Viajes y excursiones',
  ],
  'Servicios y pagos fijos': [
    'Renta o hipoteca',
    'Electricidad, agua y gas',
    'Internet y telefonía',
    'Servicios básicos',
    'Suscripciones digitales (Spotify, Netflix, Apps)',
  ],
  'Ropa y accesorios': [
    'Ropa y calzado',
    'Accesorios y joyería',
    'Cosméticos y cuidado personal',
  ],
  'Salud y bienestar': [
    'Medicamentos y consultas médicas',
    'Gimnasio y deportes',
    'Productos de higiene personal',
  ],
  'Educación': [
    'Colegiaturas y libros',
    'Cursos en línea y certificaciones',
    'Material escolar y papelería',
    'Idiomas',
  ],
  'Otros': [
    'Regalos y donaciones',
    'Gastos imprevistos',
    'Gastos no clasificados',
  ],
};

/// Subcategorías que caen en el Cubo B (Opcional/Deseos): todo lo
/// demás se considera Cubo A (Vital) por default.
///
/// NOTA: esta clasificación es un punto de partida razonable a partir
/// de tu propuesta, pero es una decisión de diseño, no una regla
/// explícita palabra por palabra del documento — coméntalo con tu
/// asesor si alguna subcategoría debería moverse de cubo.
const Set<String> _opcionalSubcategories = {
  'Restaurantes y comida rápida',
  'Cafeterías y bebidas',
  'Comida a domicilio (delivery)',
  'Cine, conciertos y eventos',
  'Bares y antros',
  'Gaming / In-game purchases',
  'Videojuegos y suscripciones de streaming',
  'Viajes y excursiones',
  'Suscripciones digitales (Spotify, Netflix, Apps)',
  'Ropa y calzado',
  'Accesorios y joyería',
  'Cosméticos y cuidado personal',
  'Gimnasio y deportes',
  'Regalos y donaciones',
  'Gastos no clasificados',
};

/// Devuelve 'Vital' u 'Opcional' según la subcategoría. Es la única
/// fuente de verdad para esta clasificación en toda la app.
String classifySubcategory(String subcategory) {
  return _opcionalSubcategories.contains(subcategory) ? 'Opcional' : 'Vital';
}
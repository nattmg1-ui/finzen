/// Contenido educativo del Módulo 9. Es información fija (no viene de
/// Firestore ni se guarda por usuario): de solo lectura, sin
/// mecanismos de escritura, calificación o gamificación (RQNF).
class LessonModel {
  final String id;
  final String title;
  final String category; // Presupuesto, Ahorro, Deudas, Tarjetas, Gastos fijos y variables
  final String type; // Artículo, Infografía, Mini-lección
  final String summary;
  final String body;

  const LessonModel({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.summary,
    required this.body,
  });
}
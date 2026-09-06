import 'package:flutter/material.dart';
import '../models/lesson_model.dart';

/// Pantalla de solo lectura. A propósito NO tiene ningún botón de
/// "completar", quiz, ni indicador de progreso — el RQNF exige que el
/// contenido educativo se muestre sin mecanismos de escritura,
/// calificación o gamificación interactiva.
class LessonDetailView extends StatelessWidget {
  final LessonModel lesson;

  const LessonDetailView({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.category), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE89A3C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lesson.type,
                style: const TextStyle(color: Color(0xFFE89A3C), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(lesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(lesson.body, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../data/lessons_data.dart';
import '../models/lesson_model.dart';
import 'lesson_detail_view.dart';

/// El usuario puede consultar cualquier lección en cualquier momento
/// (RQF: sin niveles previos ni requisitos de desbloqueo).
class EducationView extends StatefulWidget {
  const EducationView({super.key});

  @override
  State<EducationView> createState() => _EducationViewState();
}

class _EducationViewState extends State<EducationView> {
  String _selectedCategory = 'Todo';

  static const List<String> _categories = [
    'Todo',
    'Presupuesto',
    'Ahorro',
    'Deudas',
    'Tarjetas',
    'Gastos fijos y variables',
  ];

  static const Map<String, IconData> _typeIcons = {
    'Artículo': Icons.article_outlined,
    'Infografía': Icons.image_outlined,
    'Mini-lección': Icons.school_outlined,
  };

  List<LessonModel> get _filteredLessons {
    if (_selectedCategory == 'Todo') return allLessons;
    return allLessons.where((l) => l.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Educación financiera'), elevation: 0),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  selectedColor: const Color(0xFFE89A3C),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredLessons.length,
              itemBuilder: (context, index) {
                final lesson = _filteredLessons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE89A3C).withOpacity(0.15),
                      child: Icon(_typeIcons[lesson.type] ?? Icons.article_outlined, color: const Color(0xFFE89A3C)),
                    ),
                    title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(lesson.summary, style: const TextStyle(fontSize: 12)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LessonDetailView(lesson: lesson))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
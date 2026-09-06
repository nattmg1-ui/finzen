import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una meta de ahorro (Módulo 5).
class SavingsGoalModel {
  final String id;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final String priority; // 'Alta', 'Media', 'Baja'
  final DateTime deadline;
  final DateTime? createdAt;
  final bool completed;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.priority,
    required this.deadline,
    this.createdAt,
    this.completed = false,
  });

  double get progress => targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1).toDouble();

  factory SavingsGoalModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return SavingsGoalModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      targetAmount: data['targetAmount'] as int? ?? 0,
      currentAmount: data['currentAmount'] as int? ?? 0,
      priority: data['priority'] as String? ?? 'Media',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completed: data['completed'] as bool? ?? false,
    );
  }
}
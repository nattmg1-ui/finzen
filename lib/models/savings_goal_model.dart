import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una meta de ahorro (Módulo 5).
class SavingsGoalModel {
  final String id;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final String priority; // 'Alta', 'Media', 'Baja'
  final String type; // 'Vital' u 'Opcional' — distinto de prioridad, define el orden de pausado
  final DateTime deadline;
  final DateTime? createdAt;
  final bool completed;

  /// Estado de pausado, GUARDADO (no se recalcula solo cada vez, para
  /// poder recordar el orden exacto en que se fue pausando cada meta
  /// y así reactivarlas en orden inverso, como pide el RQF).
  final bool paused;
  final DateTime? pausedAt;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.priority,
    required this.type,
    required this.deadline,
    this.createdAt,
    this.completed = false,
    this.paused = false,
    this.pausedAt,
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
      type: data['type'] as String? ?? 'Opcional',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completed: data['completed'] as bool? ?? false,
      paused: data['paused'] as bool? ?? false,
      pausedAt: (data['pausedAt'] as Timestamp?)?.toDate(),
    );
  }
}
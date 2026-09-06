import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro histórico de un aporte a una meta de ahorro (Cubo C).
/// Antes de esto, "Aportar" solo sumaba a un total acumulado sin
/// dejar rastro de CUÁNDO se hizo cada aporte — necesario para poder
/// calcular cuánto se destinó al Cubo C dentro de un ciclo específico.
class GoalContributionModel {
  final String id;
  final String goalId;
  final int amount;
  final DateTime createdAt;

  GoalContributionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.createdAt,
  });

  factory GoalContributionModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return GoalContributionModel(
      id: doc.id,
      goalId: data['goalId'] as String? ?? '',
      amount: data['amount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
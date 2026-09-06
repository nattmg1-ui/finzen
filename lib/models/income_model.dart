import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una fuente de ingreso registrada por el usuario.
class IncomeModel {
  final String id;
  final String type;
  final String frequency;
  final int amount;

  /// Fecha que el usuario elige: "desde cuándo tengo este ingreso".
  /// Es la que usa el motor de ciclos (Módulo 8) para todos sus
  /// cálculos — distinta de createdAt, que es automática.
  final DateTime date;

  final DateTime? createdAt;

  IncomeModel({
    required this.id,
    required this.type,
    required this.frequency,
    required this.amount,
    required this.date,
    this.createdAt,
  });

  factory IncomeModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return IncomeModel(
      id: doc.id,
      type: data['type'] as String? ?? '',
      frequency: data['frequency'] as String? ?? '',
      amount: data['amount'] as int? ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'frequency': frequency,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
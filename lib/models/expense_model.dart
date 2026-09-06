import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un gasto registrado por el usuario (Módulo 4).
class ExpenseModel {
  final String id;
  final String category;
  final String subcategory;
  final String essentialType;
  final int amount;
  final String description;
  final DateTime date;

  /// Fecha en que el REGISTRO se creó en el sistema (distinta a
  /// `date`, que es la fecha del gasto elegida por el usuario). Se
  /// usa para bloquear edición/eliminación después de 1 mes.
  final DateTime? createdAt;

  ExpenseModel({
    required this.id,
    required this.category,
    required this.subcategory,
    required this.essentialType,
    required this.amount,
    required this.description,
    required this.date,
    this.createdAt,
  });

  factory ExpenseModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ExpenseModel(
      id: doc.id,
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      essentialType: data['essentialType'] as String? ?? 'Opcional',
      amount: data['amount'] as int? ?? 0,
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'subcategory': subcategory,
      'essentialType': essentialType,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
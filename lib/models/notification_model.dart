import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de notificación definidos por el Módulo 6.
class NotificationModel {
  final String id;
  final String type; // expense_alert | goal_progress | margin_warning | support_message | saving_pressure
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String dedupKey;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    required this.dedupKey,
  });

  factory NotificationModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return NotificationModel(
      id: doc.id,
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
      dedupKey: data['dedupKey'] as String? ?? '',
    );
  }
}
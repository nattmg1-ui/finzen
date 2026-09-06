import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get _requireUid {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('No hay un usuario autenticado.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _db.collection('users').doc(_requireUid).collection('notifications');

  Stream<List<NotificationModel>> watchNotifications() {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NotificationModel.fromDoc).toList());
  }

  Future<void> add({
    required String type,
    required String title,
    required String message,
    required String dedupKey,
  }) {
    return _notificationsRef.add({
      'type': type,
      'title': title,
      'message': message,
      'dedupKey': dedupKey,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// RQNF: no más de 2 notificaciones despachadas por día.
  Future<int> countCreatedToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snapshot = await _notificationsRef
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    return snapshot.docs.length;
  }

  /// Evita duplicar la misma alerta. Para alertas diarias, dedupKey
  /// ya incluye la fecha de hoy; para alertas "una sola vez" (como el
  /// 50% de una meta), dedupKey no cambia con el tiempo.
  Future<bool> existsWithDedupKey(String dedupKey) async {
    final snapshot = await _notificationsRef.where('dedupKey', isEqualTo: dedupKey).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> markRead(String id) {
    return _notificationsRef.doc(id).update({'read': true});
  }

  Future<void> markAllRead() async {
    final snapshot = await _notificationsRef.where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/savings_goal_model.dart';

class SavingsGoalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get _requireUid {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('No hay un usuario autenticado.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _goalsRef =>
      _db.collection('users').doc(_requireUid).collection('goals');

  CollectionReference<Map<String, dynamic>> get _contributionsRef =>
      _db.collection('users').doc(_requireUid).collection('goalContributions');

  Stream<List<SavingsGoalModel>> watchGoals() {
    return _goalsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SavingsGoalModel.fromDoc).toList());
  }

  Future<void> addGoal({
    required String name,
    required int targetAmount,
    required String priority,
    required String type,
    required DateTime deadline,
  }) {
    return _goalsRef.add({
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': 0,
      'priority': priority,
      'type': type,
      'deadline': Timestamp.fromDate(deadline),
      'completed': false,
      'paused': false,
      'pausedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGoal({
    required String goalId,
    required String name,
    required int targetAmount,
    required String priority,
    required String type,
    required DateTime deadline,
  }) {
    return _goalsRef.doc(goalId).update({
      'name': name,
      'targetAmount': targetAmount,
      'priority': priority,
      'type': type,
      'deadline': Timestamp.fromDate(deadline),
    });
  }

  /// Pausa o reactiva una meta. Al pausar, guarda CUÁNDO se pausó
  /// (para poder reactivar en orden inverso más adelante). Al
  /// reactivar, borra esa marca de tiempo.
  Future<void> setPaused(String goalId, {required bool paused}) {
    return _goalsRef.doc(goalId).update({
      'paused': paused,
      'pausedAt': paused ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> addFunds({
    required String goalId,
    required int currentAmount,
    required int targetAmount,
    required int amountToAdd,
  }) async {
    final newAmount = currentAmount + amountToAdd;
    await _goalsRef.doc(goalId).update({
      'currentAmount': newAmount,
      'completed': newAmount >= targetAmount,
    });
    await _contributionsRef.add({
      'goalId': goalId,
      'amount': amountToAdd,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  CollectionReference<Map<String, dynamic>> get contributionsRef => _contributionsRef;

  Future<void> deleteGoal(String goalId) {
    return _goalsRef.doc(goalId).delete();
  }
}
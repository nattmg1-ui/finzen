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

  /// Historial de aportes (Cubo C), plano y separado de cada meta,
  /// para poder consultarlo fácilmente por ciclo sin necesitar
  /// consultas entre subcolecciones (collectionGroup).
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
    required DateTime deadline,
  }) {
    return _goalsRef.add({
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': 0,
      'priority': priority,
      'deadline': Timestamp.fromDate(deadline),
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGoal({
    required String goalId,
    required String name,
    required int targetAmount,
    required String priority,
    required DateTime deadline,
  }) {
    return _goalsRef.doc(goalId).update({
      'name': name,
      'targetAmount': targetAmount,
      'priority': priority,
      'deadline': Timestamp.fromDate(deadline),
    });
  }

  /// El usuario "aporta" dinero a una meta. Además de sumar al total
  /// acumulado, ahora también deja un registro histórico con fecha
  /// (necesario para el Cubo C del Módulo 8).
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

  Stream<List<Map<String, dynamic>>> _rawContributions() {
    return _contributionsRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  /// Expuesto para que GoalContributionService pueda leer el
  /// historial sin duplicar la referencia a la colección.
  CollectionReference<Map<String, dynamic>> get contributionsRef => _contributionsRef;

  Future<void> deleteGoal(String goalId) {
    return _goalsRef.doc(goalId).delete();
  }
}
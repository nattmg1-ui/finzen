import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/income_model.dart';

class IncomeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get _requireUid {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('No hay un usuario autenticado.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _incomesRef =>
      _db.collection('users').doc(_requireUid).collection('incomes');

  Stream<List<IncomeModel>> watchIncomes() {
    return _incomesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(IncomeModel.fromDoc).toList());
  }

  Future<List<IncomeModel>> fetchIncomesOnce() async {
    final snapshot = await _incomesRef.orderBy('createdAt', descending: true).get(const GetOptions(source: Source.server));
    return snapshot.docs.map(IncomeModel.fromDoc).toList();
  }

  Future<void> addIncome({
    required String type,
    required String frequency,
    required int amount,
    required DateTime date,
  }) {
    return _incomesRef.add({
      'type': type,
      'frequency': frequency,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateIncome({
    required String incomeId,
    required String type,
    required String frequency,
    required int amount,
    required DateTime date,
  }) {
    return _incomesRef.doc(incomeId).update({
      'type': type,
      'frequency': frequency,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteIncome(String incomeId) {
    return _incomesRef.doc(incomeId).delete();
  }
}
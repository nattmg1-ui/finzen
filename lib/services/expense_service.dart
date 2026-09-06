import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get _requireUid {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('No hay un usuario autenticado.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _expensesRef =>
      _db.collection('users').doc(_requireUid).collection('expenses');

  Stream<List<ExpenseModel>> watchExpenses() {
    return _expensesRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ExpenseModel.fromDoc).toList());
  }

  Future<void> addExpense({
    required String category,
    required String subcategory,
    required String essentialType,
    required int amount,
    required String description,
    required DateTime date,
  }) {
    return _expensesRef.add({
      'category': category,
      'subcategory': subcategory,
      'essentialType': essentialType,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza un gasto existente. Se usa cuando el usuario edita un
  /// registro ya guardado (RQF que faltaba: modificar un gasto).
  Future<void> updateExpense({
    required String expenseId,
    required String category,
    required String subcategory,
    required String essentialType,
    required int amount,
    required String description,
    required DateTime date,
  }) {
    return _expensesRef.doc(expenseId).update({
      'category': category,
      'subcategory': subcategory,
      'essentialType': essentialType,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String expenseId) {
    return _expensesRef.doc(expenseId).delete();
  }
}
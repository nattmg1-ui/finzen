import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  CollectionReference<Map<String, dynamic>> get _usersRef => _db.collection('users');

  String get _requireUid {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('No hay un usuario autenticado.');
    return uid;
  }

  Future<void> ensureUserDocExists() async {
    final doc = await _usersRef.doc(_requireUid).get();
    if (!doc.exists) {
      await _usersRef.doc(_requireUid).set({
        'name': '',
        'email': '',
        'diagnosisCompleted': false,
        'themeMode': 'light',
        'notifyExpenseAlerts': true,
        'notifyGoalAlerts': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> createUserProfile({required String uid, required String name, required String email}) {
    return _usersRef.doc(uid).set({
      'name': name,
      'email': email,
      'diagnosisCompleted': false,
      'themeMode': 'light',
      'notifyExpenseAlerts': true,
      'notifyGoalAlerts': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveDiagnosis(Map<String, dynamic> answers) {
    return _usersRef.doc(_requireUid).update({
      'diagnosis': answers,
      'diagnosisCompleted': true,
      'diagnosisCompletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser?> fetchCurrentUserProfile() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  /// Stream en tiempo real del perfil, usado por Configuración y por
  /// main.dart para aplicar el tema Claro/Oscuro sin reiniciar la app.
  Stream<AppUser?> watchCurrentUserProfile() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(uid, doc.data()!);
    });
  }

  /// RQNF: el sistema guarda automáticamente los cambios de datos
  /// personales — se llama apenas el usuario confirma la edición.
  Future<void> updateName(String name) {
    return _usersRef.doc(_requireUid).update({'name': name});
  }

  /// Actualiza el correo mostrado en el perfil. NOTA: esto solo
  /// cambia el dato en Firestore, no el correo real de Firebase Auth
  /// (eso requiere verificación y solo aplica una vez que Login/
  /// Registro estén conectados con cuentas reales).
  Future<void> updateEmailDisplay(String email) {
    return _usersRef.doc(_requireUid).update({'email': email});
  }

  Future<void> updateThemeMode(String themeMode) {
    return _usersRef.doc(_requireUid).update({'themeMode': themeMode});
  }

  Future<void> updateNotificationPreference({bool? expenseAlerts, bool? goalAlerts}) {
    final updates = <String, dynamic>{};
    if (expenseAlerts != null) updates['notifyExpenseAlerts'] = expenseAlerts;
    if (goalAlerts != null) updates['notifyGoalAlerts'] = goalAlerts;
    if (updates.isEmpty) return Future.value();
    return _usersRef.doc(_requireUid).update(updates);
  }
}
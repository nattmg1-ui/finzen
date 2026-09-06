import 'package:firebase_auth/firebase_auth.dart';

/// Único punto de contacto entre la app y Firebase Authentication.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<UserCredential> signUp({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  /// Vuelve a verificar la identidad del usuario con su contraseña
  /// ACTUAL antes de permitir un cambio sensible (Módulo 3: no se
  /// puede cambiar la contraseña sin dar la anterior). Firebase exige
  /// esto para operaciones sensibles como cambiar la contraseña.
  Future<void> reauthenticateWithPassword(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay una cuenta con correo/contraseña asociada a este usuario.');
    }
    final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
  }

  /// Cambia la contraseña del usuario actual. Debe llamarse DESPUÉS
  /// de reauthenticateWithPassword() para confirmar que quien pide el
  /// cambio de verdad conoce la contraseña anterior.
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay un usuario autenticado.');
    }
    await user.updatePassword(newPassword);
  }

  String mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ese correo ya está registrado. Intenta iniciar sesión.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Tu contraseña actual es incorrecta.';
      case 'requires-recent-login':
        return 'Por seguridad, necesitas iniciar sesión de nuevo antes de cambiar tu contraseña.';
      case 'network-request-failed':
        return 'No hay conexión a internet. Verifica tu red.';
      default:
        return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }
}
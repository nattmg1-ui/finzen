import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Controller del Módulo 1 (Registro, Autenticación y Perfil).
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = false;
  String? errorMessage;

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*?[0-9])(?=.*?[!@#\$&*~._]).{8,}$');
    return regex.hasMatch(password);
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  String? validateLoginInput(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      return 'Por favor, ingresa tu correo y contraseña';
    }
    return null;
  }

  String? validateRegisterInput(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) {
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return 'Por favor, completa todos los campos obligatorios';
    }
    if (!_isValidEmail(email)) {
      return 'El correo electrónico no cumple con un formato válido';
    }
    if (!_isValidPassword(password)) {
      return 'La contraseña debe tener al menos 8 caracteres, un número y un carácter especial';
    }
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden. Inténtalo de nuevo.';
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _authService.mapAuthError(e);
      isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signUp(email: email, password: password);
      final uid = credential.user!.uid;
      await _firestoreService.createUserProfile(uid: uid, name: name, email: email);
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _authService.mapAuthError(e);
      isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
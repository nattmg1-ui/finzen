import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AppUser? user;
  bool isLoading = true;
  String? errorMessage;

  ProfileController() {
    _firestoreService.watchCurrentUserProfile().listen((data) {
      user = data;
      isLoading = false;
      notifyListeners();
    });
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*?[0-9])(?=.*?[!@#\$&*~._]).{8,}$');
    return regex.hasMatch(password);
  }

  Future<bool> updateName(String name) async {
    if (name.trim().isEmpty) {
      errorMessage = 'El nombre no puede estar vacío';
      notifyListeners();
      return false;
    }
    try {
      await _firestoreService.updateName(name.trim());
      errorMessage = null;
      return true;
    } catch (_) {
      errorMessage = 'No se pudo guardar el nombre. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  /// Requiere la contraseña ACTUAL antes de permitir el cambio.
  /// Primero re-autentica; si la contraseña actual es incorrecta, se
  /// rechaza ahí mismo y nunca se intenta el cambio.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.trim().isEmpty) {
      errorMessage = 'Ingresa tu contraseña actual';
      notifyListeners();
      return false;
    }
    if (!_isValidPassword(newPassword)) {
      errorMessage = 'La nueva contraseña debe tener al menos 8 caracteres, un número y un carácter especial';
      notifyListeners();
      return false;
    }
    if (newPassword != confirmPassword) {
      errorMessage = 'Las contraseñas nuevas no coinciden';
      notifyListeners();
      return false;
    }
    if (newPassword == currentPassword) {
      errorMessage = 'La nueva contraseña debe ser distinta a la actual';
      notifyListeners();
      return false;
    }

    try {
      await _authService.reauthenticateWithPassword(currentPassword);
    } on FirebaseAuthException catch (e) {
      errorMessage = _authService.mapAuthError(e);
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'No se pudo verificar tu contraseña actual.';
      notifyListeners();
      return false;
    }

    try {
      await _authService.changePassword(newPassword);
      errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _authService.mapAuthError(e);
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'No se pudo cambiar la contraseña. Intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<void> setThemeMode(String mode) async {
    await _firestoreService.updateThemeMode(mode);
  }

  Future<void> toggleExpenseAlerts(bool value) async {
    await _firestoreService.updateNotificationPreference(expenseAlerts: value);
  }

  Future<void> toggleGoalAlerts(bool value) async {
    await _firestoreService.updateNotificationPreference(goalAlerts: value);
  }
}
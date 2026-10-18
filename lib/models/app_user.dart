import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa el documento de un usuario guardado en Firestore
/// dentro de la colección `users`.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final bool diagnosisCompleted;
  final Map<String, dynamic>? diagnosis;
  final DateTime? createdAt;
  final String themeMode; // 'light' u 'oscuro' -> 'light' | 'dark'
  final bool notifyExpenseAlerts;
  final bool notifyGoalAlerts;

  // Módulo 1: recomendaciones de los primeros 14 días.
  final List<String> onboardingShownIds;
  final String? onboardingLastDate; // 'YYYY-MM-DD'
  final List<String> onboardingTodayIds;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.diagnosisCompleted,
    this.diagnosis,
    this.createdAt,
    this.themeMode = 'light',
    this.notifyExpenseAlerts = true,
    this.notifyGoalAlerts = true,
    this.onboardingShownIds = const [],
    this.onboardingLastDate,
    this.onboardingTodayIds = const [],
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      diagnosisCompleted: data['diagnosisCompleted'] as bool? ?? false,
      diagnosis: data['diagnosis'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      themeMode: data['themeMode'] as String? ?? 'light',
      notifyExpenseAlerts: data['notifyExpenseAlerts'] as bool? ?? true,
      notifyGoalAlerts: data['notifyGoalAlerts'] as bool? ?? true,
      onboardingShownIds: (data['onboardingShownIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      onboardingLastDate: data['onboardingLastDate'] as String?,
      onboardingTodayIds: (data['onboardingTodayIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'diagnosisCompleted': diagnosisCompleted,
      if (diagnosis != null) 'diagnosis': diagnosis,
      'themeMode': themeMode,
      'notifyExpenseAlerts': notifyExpenseAlerts,
      'notifyGoalAlerts': notifyGoalAlerts,
    };
  }
}
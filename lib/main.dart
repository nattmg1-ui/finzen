import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/local_notification_service.dart';
import 'models/app_user.dart';
import 'views/login_view.dart';
import 'views/diagnosis_intro_view.dart';
import 'views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final localNotifications = LocalNotificationService();
  await localNotifications.init();
  await localNotifications.requestPermission();

  runApp(const FinZenApp());
}

class FinZenApp extends StatelessWidget {
  const FinZenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _bootstrapApp();
        }

        final user = authSnapshot.data;

        return StreamBuilder<AppUser?>(
          stream: user == null ? Stream<AppUser?>.empty() : FirestoreService().watchCurrentUserProfile(),
          builder: (context, profileSnapshot) {
            final themeMode = profileSnapshot.data?.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;

            return MaterialApp(
              title: 'FinZen',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE89A3C)),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE89A3C), brightness: Brightness.dark),
                useMaterial3: true,
              ),
              home: _resolveHome(user, profileSnapshot),
            );
          },
        );
      },
    );
  }

  Widget _bootstrapApp() {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Widget _resolveHome(User? user, AsyncSnapshot<AppUser?> profileSnapshot) {
    if (user == null) return const LoginView();

    if (profileSnapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = profileSnapshot.data;
    if (profile == null || !profile.diagnosisCompleted) {
      return const DiagnosisIntroView();
    }

    return const DashboardView();
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'admin_shell.dart';
import 'features/auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ← TAMBAHKAN INI — matikan persistence di web
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false, // ← ini penyebab utama bug
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await initializeDateFormatting('id_ID');
  runApp(const KarierKuAdminApp());
}

class KarierKuAdminApp extends StatelessWidget {
  const KarierKuAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KarierKu Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthWrapper(),
    );
  }
}

// Otomatis arahkan ke Login atau Dashboard
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading saat cek status auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Sudah login → ke AdminShell
        if (snapshot.hasData && snapshot.data != null) {
          return const AdminShell();
        }

        // Belum login → ke LoginScreen
        return const LoginScreen();
      },
    );
  }
}

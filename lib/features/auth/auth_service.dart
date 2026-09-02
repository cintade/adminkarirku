import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream status login (auto listen)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Cek apakah role == admin
      final token = await credential.user!.getIdTokenResult(true);
      if (token.claims?['role'] != 'admin') {
        await _auth.signOut();
        return 'Akun ini bukan Admin!';
      }

      return null; // null = sukses
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Email tidak ditemukan';
        case 'wrong-password':
          return 'Password salah';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti';
        default:
          return 'Login gagal: ${e.message}';
      }
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Cek user aktif
  User? get currentUser => _auth.currentUser;
}

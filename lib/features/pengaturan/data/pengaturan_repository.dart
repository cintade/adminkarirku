import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pengaturan_model.dart';

class PengaturanRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════════════════════════════════
  // PROFIL & PASSWORD
  // ═══════════════════════════════════════════════════════════════════════

  /// Ambil profil admin yang SEDANG LOGIN. Kalau belum ada dokumen di
  /// `admins/{uid}` (mis. admin pertama dibuat manual lewat Firebase
  /// Console), fallback pakai data dari Firebase Auth saja.
  Future<AdminAccount?> getProfilSaatIni() async {
    // Tunggu Firebase Auth selesai memuat ulang sesi (penting di Web,
    // supaya tidak "keburu" baca currentUser sebelum Firebase siap).
    final user = await _auth.authStateChanges().first;
    if (user == null) return null;
    final doc = await _db.collection('admins').doc(user.uid).get();
    if (!doc.exists) {
      return AdminAccount(
        uid: user.uid,
        nama: user.displayName ?? '',
        email: user.email ?? '',
        role: 'Admin',
      );
    }
    return AdminAccount.fromFirestore(doc);
  }

  Future<void> updateProfil({required String uid, required String nama}) async {
    await _db.collection('admins').doc(uid).set(
      {'nama': nama},
      SetOptions(merge: true),
    );
    await _auth.currentUser?.updateDisplayName(nama);
  }

  /// Ubah password admin yang sedang login. Firebase mewajibkan
  /// re-autentikasi (masukkan password lama) sebelum boleh ganti password,
  /// demi keamanan.
  Future<void> ubahPassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Sesi tidak valid, silakan login ulang');
    }
    final cred = EmailAuthProvider.credential(
        email: user.email!, password: passwordLama);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(passwordBaru);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // KONFIGURASI BOBOT REKOMENDASI
  // ═══════════════════════════════════════════════════════════════════════

  Future<PengaturanRekomendasi> getKonfigurasiRekomendasi() async {
    final doc =
        await _db.collection('pengaturan_sistem').doc('rekomendasi').get();
    return PengaturanRekomendasi.fromFirestore(doc.data());
  }

  Future<void> simpanKonfigurasiRekomendasi(
      PengaturanRekomendasi konfig) async {
    await _db.collection('pengaturan_sistem').doc('rekomendasi').set({
      ...konfig.toFirestore(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MANAJEMEN ADMIN
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<AdminAccount>> getSemuaAdmin() async {
    final snap = await _db.collection('admins').get();
    return snap.docs.map(AdminAccount.fromFirestore).toList()
      ..sort((a, b) => a.nama.compareTo(b.nama));
  }

  /// Tambah admin baru TANPA mengganggu sesi admin yang sedang login.
  ///
  /// CATATAN TEKNIS: `createUserWithEmailAndPassword` di Firebase Auth
  /// client SDK otomatis login sebagai user yang BARU dibuat — kalau
  /// dipanggil langsung dari _auth utama, admin yang sedang login akan
  /// ke-logout dan tergantikan sesi admin baru. Untuk menghindari itu,
  /// kita buat FirebaseApp KEDUA yang sifatnya sementara khusus untuk
  /// membuat akun, lalu dihapus lagi setelah selesai — sesi admin utama
  /// sama sekali tidak tersentuh.
  ///
  /// (Alternatif yang lebih "benar" untuk production: pindahkan proses ini
  /// ke Cloud Function yang pakai Firebase Admin SDK, supaya tidak perlu
  /// trik seperti ini dan sekalian bisa hapus akun Auth juga. Tapi ini
  /// butuh backend/Cloud Functions terpisah dari Flutter web ini.)
  Future<void> tambahAdmin({
    required String nama,
    required String email,
    required String password,
    required String role,
  }) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'tempAdminCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUid = cred.user!.uid;
      await tempAuth.signOut();

      await _db.collection('admins').doc(newUid).set({
        'nama': nama,
        'email': email,
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });
    } finally {
      // Selalu bersihkan FirebaseApp sementara, sukses maupun gagal.
      if (tempApp != null) await tempApp.delete();
    }
  }

  /// Cabut akses panel admin (hapus dokumen di `admins`). Akun Firebase
  /// Auth-nya TIDAK ikut terhapus (butuh Admin SDK/Cloud Function untuk
  /// itu) — tapi begitu dokumen ini hilang, orang tsb tidak akan lolos
  /// pengecekan otorisasi admin lagi (asumsikan aplikasi kamu mengecek
  /// keberadaan dokumen `admins/{uid}` sebagai syarat akses panel).
  Future<void> cabutAksesAdmin(String uid) async {
    await _db.collection('admins').doc(uid).delete();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Service ini dipanggil dari MOBILE setiap ada aktivitas penting.
/// Hasilnya akan muncul di dashboard admin secara real-time.
class AktivitasService {
  static final _db = FirebaseFirestore.instance;
  static final _col = _db.collection('aktivitas');

  /// Catat aktivitas baru — dipanggil dari mobile
  static Future<void> catat({
    required String deskripsi,
    required String tipe, // 'tes' | 'roadmap' | 'daftar' | 'admin'
    String? userId,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await _col.add({
        'deskripsi': deskripsi,
        'tipe': tipe,
        'waktu': FieldValue.serverTimestamp(),
        'user_id': userId,
        if (extra != null) ...extra,
      });
    } catch (e) {
      // Silent fail — jangan sampai error aktivitas ganggu UX
      debugPrint('AktivitasService error: $e');
    }
  }

  // ── Helper methods yang dipanggil dari mobile ─────────────────────────

  /// Dipanggil saat mahasiswa selesai tes RIASEC
  static Future<void> tesRiasecSelesai(String namaMahasiswa, String uid) =>
      catat(
        deskripsi: '$namaMahasiswa selesai tes RIASEC',
        tipe: 'tes',
        userId: uid,
        extra: {'jenis_tes': 'riasec'},
      );

  /// Dipanggil saat mahasiswa selesai tes Sternberg
  static Future<void> tesSternbergSelesai(String namaMahasiswa, String uid) =>
      catat(
        deskripsi: '$namaMahasiswa selesai tes Sternberg',
        tipe: 'tes',
        userId: uid,
        extra: {'jenis_tes': 'sternberg'},
      );

  /// Dipanggil saat mahasiswa selesai tes DISC
  static Future<void> tesDiscSelesai(String namaMahasiswa, String uid) => catat(
        deskripsi: '$namaMahasiswa selesai tes DISC',
        tipe: 'tes',
        userId: uid,
        extra: {'jenis_tes': 'disc'},
      );

  /// Dipanggil saat mahasiswa membuat/update roadmap
  static Future<void> roadmapDibuat(
          String namaMahasiswa, String namaKarir, String uid) =>
      catat(
        deskripsi: '$namaMahasiswa membuat roadmap: $namaKarir',
        tipe: 'roadmap',
        userId: uid,
        extra: {'karir': namaKarir},
      );

  /// Dipanggil saat mahasiswa baru mendaftar
  static Future<void> mahasiswaDaftar(String namaMahasiswa, String uid) =>
      catat(
        deskripsi: '$namaMahasiswa mendaftar di aplikasi',
        tipe: 'daftar',
        userId: uid,
      );
}

/// Contoh penggunaan di mobile (lib/features/auth/register_screen.dart):
///
/// // Setelah register berhasil:
/// await AktivitasService.mahasiswaDaftar(nama, uid);
///
/// // Setelah tes RIASEC selesai:
/// await AktivitasService.tesRiasecSelesai(namaMahasiswa, uid);
///
/// // Setelah simpan roadmap:
/// await AktivitasService.roadmapDibuat(nama, namaKarir, uid);

// ignore: avoid_print
void debugPrint(String message) => print(message);

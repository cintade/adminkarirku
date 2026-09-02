import 'package:cloud_firestore/cloud_firestore.dart';

/// Bobot-bobot yang dipakai RekomendasiKarirEngine (mobile). Disimpan di
/// Firestore `pengaturan_sistem/rekomendasi` supaya admin bisa mengubahnya
/// tanpa perlu update aplikasi mobile.
///
/// PENTING: nilai default di sini HARUS SAMA dengan default yang dipakai
/// RekomendasiKarirEngine kalau dokumen ini belum pernah dibuat, supaya
/// perilaku sistem tidak berubah tiba-tiba sebelum admin pertama kali
/// menyimpan konfigurasi.
class PengaturanRekomendasi {
  final double bobotProfileMatching; // vs bobotSaw, total harus 1.0
  final double bobotSaw;
  final double bobotCoreFactor; // vs bobotSecondaryFactor, total harus 1.0
  final double bobotSecondaryFactor;
  final double nilaiMaksimumAkademik; // 4.0 (skala IPK) atau 100 (skala 0-100)

  const PengaturanRekomendasi({
    this.bobotProfileMatching = 0.6,
    this.bobotSaw = 0.4,
    this.bobotCoreFactor = 0.6,
    this.bobotSecondaryFactor = 0.4,
    this.nilaiMaksimumAkademik = 4.0,
  });

  factory PengaturanRekomendasi.fromFirestore(Map<String, dynamic>? d) {
    if (d == null) return const PengaturanRekomendasi();
    return PengaturanRekomendasi(
      bobotProfileMatching:
          (d['bobot_profile_matching'] as num?)?.toDouble() ?? 0.6,
      bobotSaw: (d['bobot_saw'] as num?)?.toDouble() ?? 0.4,
      bobotCoreFactor: (d['bobot_core_factor'] as num?)?.toDouble() ?? 0.6,
      bobotSecondaryFactor:
          (d['bobot_secondary_factor'] as num?)?.toDouble() ?? 0.4,
      nilaiMaksimumAkademik:
          (d['nilai_maksimum_akademik'] as num?)?.toDouble() ?? 4.0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'bobot_profile_matching': bobotProfileMatching,
        'bobot_saw': bobotSaw,
        'bobot_core_factor': bobotCoreFactor,
        'bobot_secondary_factor': bobotSecondaryFactor,
        'nilai_maksimum_akademik': nilaiMaksimumAkademik,
      };
}

/// Akun admin — disimpan terpisah dari Firebase Auth di collection
/// `admins/{uid}`. Dipakai sebagai acuan otorisasi ("apakah uid ini boleh
/// masuk panel admin?") DAN sebagai sumber nama/role untuk ditampilkan,
/// karena Firebase Auth sendiri tidak punya field custom seperti role.
class AdminAccount {
  final String uid;
  final String nama;
  final String email;
  final String role; // "Super Admin" | "Admin"

  const AdminAccount({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
  });

  factory AdminAccount.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminAccount(
      uid: doc.id,
      nama: d['nama'] ?? '',
      email: d['email'] ?? '',
      role: d['role'] ?? 'Admin',
    );
  }
}

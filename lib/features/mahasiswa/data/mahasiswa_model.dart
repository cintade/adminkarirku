import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data mahasiswa yang dipakai di halaman admin "Mahasiswa".
///
/// SUMBER DATA ASLI: collection `users` (bukan `mahasiswa`).
/// Field mentah di Firestore untuk satu dokumen `users/{uid}`:
///   - firstName, lastName    : String  -> digabung jadi `nama`
///   - email                  : String
///   - studyProgram           : String  ("teknik informatika", lowercase)
///   - semester               : String  ("5", disimpan sebagai teks!)
///   - nim, phone, jenjang    : String  (belum dipakai di tabel ini)
///   - createdAt              : String/Timestamp
///
/// Field RANGKUMAN di bawah ini (riasecDominant, statusTes,
/// kesiapanPercentage, roadmapAktifCount) BELUM ADA di collection `users`
/// saat ini. Untuk sementara ditampilkan sebagai placeholder ('-' / null).
/// Rekomendasi jangka panjang: hitung nilai-nilai ini dari collection
/// hasil_riasec/{uid}, hasil_disc/{uid}, hasil_bakat/{uid}, dan roadmap
/// (where mahasiswa_id == uid), lalu tulis balik ke users/{uid} setiap
/// kali ada perubahan — supaya admin panel tidak perlu N+1 query per baris.
class MahasiswaModel {
  final String id;
  final String nama;
  final String email;
  final String prodi;
  final int semester;
  final String riasecDominant;
  final String statusTes; // Lengkap | Sebagian | Belum
  final double? kesiapanPercentage;
  final int roadmapAktifCount;
  final DateTime? createdAt;

  MahasiswaModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.prodi,
    required this.semester,
    required this.riasecDominant,
    required this.statusTes,
    required this.kesiapanPercentage,
    required this.roadmapAktifCount,
    required this.createdAt,
  });

  factory MahasiswaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final firstName = (data['firstName'] ?? '').toString().trim();
    final lastName = (data['lastName'] ?? '').toString().trim();
    final namaGabungan =
        [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    // semester disimpan sebagai String di Firestore (mis. "5"),
    // jadi wajib di-parse, jangan langsung dianggap int.
    final semesterMentah = data['semester'];
    final semesterInt = semesterMentah is int
        ? semesterMentah
        : int.tryParse('$semesterMentah') ?? 0;

    return MahasiswaModel(
      id: doc.id,
      nama: namaGabungan.isEmpty ? '-' : namaGabungan,
      email: (data['email'] ?? '-') as String,
      prodi: (data['studyProgram'] ?? '-') as String,
      semester: semesterInt,
      // Belum ada datanya di Firestore, tampilkan placeholder dulu.
      riasecDominant: (data['riasecDominant'] ?? '-') as String,
      statusTes: (data['statusTes'] ?? 'Belum') as String,
      kesiapanPercentage: data['kesiapanPercentage'] == null
          ? null
          : (data['kesiapanPercentage'] as num).toDouble(),
      roadmapAktifCount: (data['roadmapAktifCount'] is int)
          ? data['roadmapAktifCount'] as int
          : int.tryParse('${data['roadmapAktifCount']}') ?? 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final parts = nama.trim().split(RegExp(r'\s+'));
    return {
      'firstName': parts.isNotEmpty ? parts.first : '',
      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      'email': email,
      'studyProgram': prodi,
      'semester': '$semester', // disimpan sebagai String, samakan format
      'riasecDominant': riasecDominant,
      'statusTes': statusTes,
      'kesiapanPercentage': kesiapanPercentage,
      'roadmapAktifCount': roadmapAktifCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Inisial untuk avatar bulat, contoh "Budi Santoso" -> "BS"
  String get inisial {
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || nama == '-') return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

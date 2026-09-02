import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Model Karir (disesuaikan dengan ERD) ──────────────────────────────────
// Perubahan dari versi sebelumnya:
//  - riasec, disc, sternberg DIHAPUS dari sini -> sekarang jadi bagian dari
//    entity terpisah `aturan_rekomendasi` (relasi 1 karir : banyak aturan).
//  - Ditambahkan karirSegment1, karirSegment2, karirSegment3 sesuai ERD
//    (karir_segment1-3), merepresentasikan jenjang/level karir ini
//    (misal: Junior -> Mid -> Senior). Field ini boleh kosong jika belum
//    diisi admin.
class KarirModel {
  final String? docId; // -> karir_id (Firestore document id)
  final String nama; // -> karir_nama
  final String emoji;
  final String deskripsi; // -> karir_deskripsi
  final List<String> skillUtama; // -> skill_utama
  final List<String> mkPendukung; // -> mk_pendukung (nama MK)
  final String karirSegment1; // -> karir_segment1 (mis. level Junior)
  final String karirSegment2; // -> karir_segment2 (mis. level Mid)
  final String karirSegment3; // -> karir_segment3 (mis. level Senior)
  final int jumlahMahasiswa;
  final double rataRataKesiapan; // 0.0 - 1.0

  const KarirModel({
    this.docId,
    required this.nama,
    required this.emoji,
    required this.deskripsi,
    required this.skillUtama,
    required this.mkPendukung,
    this.karirSegment1 = '',
    this.karirSegment2 = '',
    this.karirSegment3 = '',
    this.jumlahMahasiswa = 0,
    this.rataRataKesiapan = 0.0,
  });

  factory KarirModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return KarirModel(
      docId: doc.id,
      nama: d['nama'] ?? '',
      emoji: d['emoji'] ?? '💼',
      deskripsi: d['deskripsi'] ?? '',
      skillUtama: List<String>.from(d['skill_utama'] ?? []),
      mkPendukung: List<String>.from(d['mk_pendukung'] ?? []),
      karirSegment1: d['karir_segment1'] ?? '',
      karirSegment2: d['karir_segment2'] ?? '',
      karirSegment3: d['karir_segment3'] ?? '',
      jumlahMahasiswa: (d['jumlah_mahasiswa'] as num?)?.toInt() ?? 0,
      rataRataKesiapan: (d['rata_rata_kesiapan'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'emoji': emoji,
      'deskripsi': deskripsi,
      'skill_utama': skillUtama,
      'mk_pendukung': mkPendukung,
      'karir_segment1': karirSegment1,
      'karir_segment2': karirSegment2,
      'karir_segment3': karirSegment3,
      'jumlah_mahasiswa': jumlahMahasiswa,
      'rata_rata_kesiapan': rataRataKesiapan,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  KarirModel copyWith({
    String? docId,
    String? nama,
    String? emoji,
    String? deskripsi,
    List<String>? skillUtama,
    List<String>? mkPendukung,
    String? karirSegment1,
    String? karirSegment2,
    String? karirSegment3,
    int? jumlahMahasiswa,
    double? rataRataKesiapan,
  }) {
    return KarirModel(
      docId: docId ?? this.docId,
      nama: nama ?? this.nama,
      emoji: emoji ?? this.emoji,
      deskripsi: deskripsi ?? this.deskripsi,
      skillUtama: skillUtama ?? this.skillUtama,
      mkPendukung: mkPendukung ?? this.mkPendukung,
      karirSegment1: karirSegment1 ?? this.karirSegment1,
      karirSegment2: karirSegment2 ?? this.karirSegment2,
      karirSegment3: karirSegment3 ?? this.karirSegment3,
      jumlahMahasiswa: jumlahMahasiswa ?? this.jumlahMahasiswa,
      rataRataKesiapan: rataRataKesiapan ?? this.rataRataKesiapan,
    );
  }
}

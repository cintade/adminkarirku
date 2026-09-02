import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data Mata Kuliah.
/// Collection Firestore: "mata_kuliah" (perhatikan underscore — sesuai
/// struktur data yang sudah ada di project KarierKu kamu).
///
/// PENTING soal ID: [mkId] diambil dari FIELD "mk_id" di dalam dokumen
/// (misalnya "MK005"), BUKAN dari Firestore Document ID otomatis.
/// Ini dipakai sebagai acuan relasi di collection "makukar" nanti
/// (mkk_mk_id), konsisten dengan konvensi ERD project kamu yang
/// memakai ID singkat seperti mk_id / kr_id sebagai foreign key,
/// bukan Document ID Firestore yang acak.
class MataKuliah {
  final String mkId; // dari field "mk_id", mis. "MK005"
  final String kode; // dari field "kode", mis. "MK005"
  final String mkNama;
  final String
      mkSegment; // dari field "mk_segment1", mis. "General & Soft Skills"
  final String mkDeskripsi;
  final int mkSks;
  final int mkSemester;
  final String mkProdi;
  final String tipe;

  MataKuliah({
    required this.mkId,
    required this.kode,
    required this.mkNama,
    required this.mkSegment,
    required this.mkDeskripsi,
    required this.mkSks,
    required this.mkSemester,
    required this.mkProdi,
    required this.tipe,
  });

  factory MataKuliah.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MataKuliah(
      // fallback ke doc.id kalau field mk_id ternyata kosong/tidak ada
      mkId:
          (data['mk_id'] ?? '').toString().isNotEmpty ? data['mk_id'] : doc.id,
      kode: data['kode'] ?? '',
      mkNama: data['mk_nama'] ?? '',
      mkSegment: data['mk_segment1'] ?? data['mk_segment'] ?? '',
      mkDeskripsi: data['mk_deskripsi'] ?? '',
      mkSks: data['mk_sks'] is int
          ? data['mk_sks']
          : int.tryParse('${data['mk_sks']}') ?? 0,
      mkSemester: data['mk_semester'] is int
          ? data['mk_semester']
          : int.tryParse('${data['mk_semester']}') ?? 0,
      mkProdi: data['mk_prodi'] ?? '',
      tipe: data['tipe'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mk_id': mkId,
      'kode': kode,
      'mk_nama': mkNama,
      'mk_segment1': mkSegment,
      'mk_deskripsi': mkDeskripsi,
      'mk_sks': mkSks,
      'mk_semester': mkSemester,
      'mk_prodi': mkProdi,
      'tipe': tipe,
    };
  }

  String get label => kode.isNotEmpty ? '$mkNama ($kode)' : mkNama;
}

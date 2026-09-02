import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Model sesuai ERD ─────────────────────────────────────────────────────────
// Fields: mk_id, mk_nama, mk_sks, mk_semester, mk_segment1-3,
//         mk_deskripsi, mk_prodi, tipe
class MataKuliah {
  final String? docId; // Firestore document ID
  final String mkId; // kode MK, e.g. "IF301"
  final String mkNama;
  final int mkSks;
  final int mkSemester;
  final String mkSegment1; // profesi relevan 1
  final String mkSegment2; // profesi relevan 2
  final String mkSegment3; // profesi relevan 3
  final String mkDeskripsi;
  final String mkProdi; // "TI" / "SI" / "MI" / dll
  final String tipe; // "Wajib" / "Pilihan" — prioritas P1-P5

  const MataKuliah({
    this.docId,
    required this.mkId,
    required this.mkNama,
    required this.mkSks,
    required this.mkSemester,
    this.mkSegment1 = '',
    this.mkSegment2 = '',
    this.mkSegment3 = '',
    this.mkDeskripsi = '',
    required this.mkProdi,
    this.tipe = 'Wajib',
  });

  // ── Profesi relevan sebagai list (untuk badge) ────────────────────────────
  List<String> get profesiList =>
      [mkSegment1, mkSegment2, mkSegment3].where((s) => s.isNotEmpty).toList();

  // ── Prioritas dari tipe (P1-P5) ───────────────────────────────────────────
  String get prioritas {
    switch (tipe) {
      case 'Wajib':
        return 'P5';
      case 'Pilihan Utama':
        return 'P4';
      case 'Pilihan':
        return 'P3';
      case 'Penunjang':
        return 'P2';
      default:
        return 'P1';
    }
  }

  // ── fromFirestore ──────────────────────────────────────────────────────────
  factory MataKuliah.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MataKuliah(
      docId: doc.id,
      mkId: d['mk_id'] ?? '',
      mkNama: d['mk_nama'] ?? '',
      mkSks: (d['mk_sks'] as num?)?.toInt() ?? 3,
      mkSemester: (d['mk_semester'] as num?)?.toInt() ?? 1,
      mkSegment1: d['mk_segment1'] ?? '',
      mkSegment2: d['mk_segment2'] ?? '',
      mkSegment3: d['mk_segment3'] ?? '',
      mkDeskripsi: d['mk_deskripsi'] ?? '',
      mkProdi: d['mk_prodi'] ?? '',
      tipe: d['tipe'] ?? 'Wajib',
    );
  }

  // ── toFirestore ────────────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
        'mk_id': mkId,
        'mk_nama': mkNama,
        'mk_sks': mkSks,
        'mk_semester': mkSemester,
        'mk_segment1': mkSegment1,
        'mk_segment2': mkSegment2,
        'mk_segment3': mkSegment3,
        'mk_deskripsi': mkDeskripsi,
        'mk_prodi': mkProdi,
        'tipe': tipe,
        // Field tambahan untuk kompatibilitas mobile
        'kode': mkId,
        'nama': mkNama,
        'sks': mkSks,
        'semester': mkSemester,
        'prodi': mkProdi,
      };

  MataKuliah copyWith({
    String? mkId,
    String? mkNama,
    int? mkSks,
    int? mkSemester,
    String? mkSegment1,
    String? mkSegment2,
    String? mkSegment3,
    String? mkDeskripsi,
    String? mkProdi,
    String? tipe,
  }) =>
      MataKuliah(
        docId: docId,
        mkId: mkId ?? this.mkId,
        mkNama: mkNama ?? this.mkNama,
        mkSks: mkSks ?? this.mkSks,
        mkSemester: mkSemester ?? this.mkSemester,
        mkSegment1: mkSegment1 ?? this.mkSegment1,
        mkSegment2: mkSegment2 ?? this.mkSegment2,
        mkSegment3: mkSegment3 ?? this.mkSegment3,
        mkDeskripsi: mkDeskripsi ?? this.mkDeskripsi,
        mkProdi: mkProdi ?? this.mkProdi,
        tipe: tipe ?? this.tipe,
      );
}

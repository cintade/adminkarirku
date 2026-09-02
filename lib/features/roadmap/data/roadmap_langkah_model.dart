import 'package:cloud_firestore/cloud_firestore.dart';

enum KategoriLangkah {
  akademik,
  softSkill,
  portofolio,
  sertifikasi,
  pengalaman,
}

extension KategoriLangkahExt on KategoriLangkah {
  String get label {
    switch (this) {
      case KategoriLangkah.akademik:
        return 'Akademik';
      case KategoriLangkah.softSkill:
        return 'Soft Skill';
      case KategoriLangkah.portofolio:
        return 'Portofolio';
      case KategoriLangkah.sertifikasi:
        return 'Sertifikasi';
      case KategoriLangkah.pengalaman:
        return 'Pengalaman';
    }
  }

  String get firestoreValue {
    switch (this) {
      case KategoriLangkah.akademik:
        return 'akademik';
      case KategoriLangkah.softSkill:
        return 'soft_skill';
      case KategoriLangkah.portofolio:
        return 'portofolio';
      case KategoriLangkah.sertifikasi:
        return 'sertifikasi';
      case KategoriLangkah.pengalaman:
        return 'pengalaman';
    }
  }

  static KategoriLangkah fromString(String? val) {
    switch (val) {
      case 'soft_skill':
        return KategoriLangkah.softSkill;
      case 'portofolio':
        return KategoriLangkah.portofolio;
      case 'sertifikasi':
        return KategoriLangkah.sertifikasi;
      case 'pengalaman':
        return KategoriLangkah.pengalaman;
      default:
        return KategoriLangkah.akademik;
    }
  }
}

enum StatusLangkah { belum, sedang, selesai }

extension StatusLangkahExt on StatusLangkah {
  String get label {
    switch (this) {
      case StatusLangkah.belum:
        return 'Belum';
      case StatusLangkah.sedang:
        return 'Sedang';
      case StatusLangkah.selesai:
        return 'Selesai';
    }
  }

  String get firestoreValue {
    switch (this) {
      case StatusLangkah.belum:
        return 'belum';
      case StatusLangkah.sedang:
        return 'sedang';
      case StatusLangkah.selesai:
        return 'selesai';
    }
  }

  static StatusLangkah fromString(String? val) {
    switch (val) {
      case 'sedang':
        return StatusLangkah.sedang;
      case 'selesai':
        return StatusLangkah.selesai;
      default:
        return StatusLangkah.belum;
    }
  }
}

/// Master data langkah roadmap
/// Collection: roadmap_langkah
/// roadmap_id = ID karir (dipakai mobile untuk query langkah per karir)
class RoadmapLangkah {
  final String? docId;
  final String karierId; // FK ke collection karir
  final int urutan; // urutan tampil di mobile
  final String deskripsi; // judul langkah
  final KategoriLangkah kategori;
  final int targetSmt; // target semester 1-8
  final String sumberGap; // RIASEC/Sternberg/DISC/Nilai MK/Manual
  final StatusLangkah status; // status default = belum

  const RoadmapLangkah({
    this.docId,
    required this.karierId,
    required this.urutan,
    required this.deskripsi,
    required this.kategori,
    required this.targetSmt,
    required this.sumberGap,
    this.status = StatusLangkah.belum,
  });

  factory RoadmapLangkah.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoadmapLangkah(
      docId: doc.id,
      // Support both field names: karir_id dan roadmap_id (sesuai ERD)
      karierId: d['karir_id'] as String? ?? d['roadmap_id'] as String? ?? '',
      urutan: (d['urutan'] as num?)?.toInt() ?? 0,
      deskripsi: d['deskripsi'] as String? ?? '',
      kategori: KategoriLangkahExt.fromString(d['kategori'] as String?),
      targetSmt: (d['target_smt'] as num?)?.toInt() ?? 1,
      sumberGap: d['sumber_gap'] as String? ?? '',
      status: StatusLangkahExt.fromString(d['status'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'karir_id': karierId, // untuk query mobile
        'roadmap_id': karierId, // alias sesuai ERD
        'urutan': urutan,
        'deskripsi': deskripsi,
        'kategori': kategori.firestoreValue,
        'target_smt': targetSmt,
        'sumber_gap': sumberGap,
        'status': status.firestoreValue,
      };

  RoadmapLangkah copyWith({
    String? docId,
    String? karierId,
    int? urutan,
    String? deskripsi,
    KategoriLangkah? kategori,
    int? targetSmt,
    String? sumberGap,
    StatusLangkah? status,
  }) =>
      RoadmapLangkah(
        docId: docId ?? this.docId,
        karierId: karierId ?? this.karierId,
        urutan: urutan ?? this.urutan,
        deskripsi: deskripsi ?? this.deskripsi,
        kategori: kategori ?? this.kategori,
        targetSmt: targetSmt ?? this.targetSmt,
        sumberGap: sumberGap ?? this.sumberGap,
        status: status ?? this.status,
      );
}

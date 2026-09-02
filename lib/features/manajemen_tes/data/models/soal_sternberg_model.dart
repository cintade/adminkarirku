import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Dimensi Kecerdasan Sternberg ─────────────────────────────────────────────
enum DimensiSternberg { analitis, kreatif, praktis }

extension DimensiSternbergExt on DimensiSternberg {
  String get label {
    switch (this) {
      case DimensiSternberg.analitis:
        return 'Analitis';
      case DimensiSternberg.kreatif:
        return 'Kreatif';
      case DimensiSternberg.praktis:
        return 'Praktis';
    }
  }

  String get firestoreValue {
    switch (this) {
      case DimensiSternberg.analitis:
        return 'analitis';
      case DimensiSternberg.kreatif:
        return 'kreatif';
      case DimensiSternberg.praktis:
        return 'praktis';
    }
  }

  static DimensiSternberg fromString(String? val) {
    switch (val) {
      case 'kreatif':
        return DimensiSternberg.kreatif;
      case 'praktis':
        return DimensiSternberg.praktis;
      default:
        return DimensiSternberg.analitis;
    }
  }
}

// ─── Format Konten ────────────────────────────────────────────────────────────
enum FormatKonten { verbal, kuantitatif, figural }

extension FormatKontenExt on FormatKonten {
  String get label {
    switch (this) {
      case FormatKonten.verbal:
        return 'Verbal';
      case FormatKonten.kuantitatif:
        return 'Kuantitatif';
      case FormatKonten.figural:
        return 'Figural';
    }
  }

  String get firestoreValue {
    switch (this) {
      case FormatKonten.verbal:
        return 'verbal';
      case FormatKonten.kuantitatif:
        return 'kuantitatif';
      case FormatKonten.figural:
        return 'figural';
    }
  }

  static FormatKonten fromString(String? val) {
    switch (val) {
      case 'kuantitatif':
        return FormatKonten.kuantitatif;
      case 'figural':
        return FormatKonten.figural;
      default:
        return FormatKonten.verbal;
    }
  }
}

// ─── Part (9 kombinasi) ───────────────────────────────────────────────────────
/// STAT dibagi 9 Part sesuai kombinasi Dimensi × Format:
///   Part 1 = Analitis-Verbal
///   Part 2 = Analitis-Kuantitatif
///   Part 3 = Analitis-Figural
///   Part 4 = Kreatif-Verbal
///   Part 5 = Kreatif-Kuantitatif
///   Part 6 = Kreatif-Figural
///   Part 7 = Praktis-Verbal
///   Part 8 = Praktis-Kuantitatif
///   Part 9 = Praktis-Figural
class StatPart {
  final int noPart; // 1–9
  final DimensiSternberg dimensi;
  final FormatKonten format;

  const StatPart({
    required this.noPart,
    required this.dimensi,
    required this.format,
  });

  String get label => 'Part $noPart — ${dimensi.label} ${format.label}';

  /// Daftar lengkap 9 part STAT
  static const List<StatPart> semuaPart = [
    StatPart(
        noPart: 1,
        dimensi: DimensiSternberg.analitis,
        format: FormatKonten.verbal),
    StatPart(
        noPart: 2,
        dimensi: DimensiSternberg.analitis,
        format: FormatKonten.kuantitatif),
    StatPart(
        noPart: 3,
        dimensi: DimensiSternberg.analitis,
        format: FormatKonten.figural),
    StatPart(
        noPart: 4,
        dimensi: DimensiSternberg.kreatif,
        format: FormatKonten.verbal),
    StatPart(
        noPart: 5,
        dimensi: DimensiSternberg.kreatif,
        format: FormatKonten.kuantitatif),
    StatPart(
        noPart: 6,
        dimensi: DimensiSternberg.kreatif,
        format: FormatKonten.figural),
    StatPart(
        noPart: 7,
        dimensi: DimensiSternberg.praktis,
        format: FormatKonten.verbal),
    StatPart(
        noPart: 8,
        dimensi: DimensiSternberg.praktis,
        format: FormatKonten.kuantitatif),
    StatPart(
        noPart: 9,
        dimensi: DimensiSternberg.praktis,
        format: FormatKonten.figural),
  ];

  /// Cari StatPart berdasarkan noPart
  static StatPart fromNoPart(int no) => semuaPart
      .firstWhere((p) => p.noPart == no, orElse: () => semuaPart.first);

  /// Cari noPart dari kombinasi dimensi + format
  static int noPartDari(DimensiSternberg dimensi, FormatKonten format) {
    return semuaPart
        .firstWhere((p) => p.dimensi == dimensi && p.format == format)
        .noPart;
  }
}

// ─── Pilihan Jawaban ──────────────────────────────────────────────────────────
class PilihanJawaban {
  final String huruf; // A, B, C, D
  final String teks;

  /// Untuk soal figural, teks bisa berisi URL gambar atau deskripsi pola
  final String? gambarUrl;

  const PilihanJawaban({
    required this.huruf,
    required this.teks,
    this.gambarUrl,
  });

  factory PilihanJawaban.fromMap(Map<String, dynamic> map) => PilihanJawaban(
        huruf: map['huruf'] as String? ?? '',
        teks: map['teks'] as String? ?? '',
        gambarUrl: map['gambarUrl'] as String?,
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'huruf': huruf,
      'teks': teks,
    };
    // Jangan masukkan key sama sekali jika null
    if (gambarUrl != null && gambarUrl!.isNotEmpty) {
      map['gambarUrl'] = gambarUrl;
    }
    return map;
  }
}

// ─── Model Soal Sternberg (STAT) ──────────────────────────────────────────────
class SoalSternberg {
  final String? docId;

  /// Nomor soal dalam satu part (1–4, karena tiap part 4 soal)
  final int noSoal;

  /// Part 1–9
  final int noPart;

  /// Dimensi: analitis / kreatif / praktis (turunan dari noPart)
  final DimensiSternberg dimensi;

  /// Format: verbal / kuantitatif / figural (turunan dari noPart)
  final FormatKonten format;

  /// Teks soal utama
  final String pernyataan;

  /// Untuk soal figural: URL gambar soal (opsional)
  final String? gambarSoalUrl;

  /// Konteks/informasi pendukung (misal: bacaan untuk verbal,
  /// data angka untuk kuantitatif, atau deskripsi pola figural)
  final String? konteks;

  /// 4 pilihan jawaban A–D
  final List<PilihanJawaban> pilihan;

  /// Huruf jawaban benar: 'A' / 'B' / 'C' / 'D'
  final String jawabanBenar;

  const SoalSternberg({
    this.docId,
    required this.noSoal,
    required this.noPart,
    required this.dimensi,
    required this.format,
    required this.pernyataan,
    this.gambarSoalUrl,
    this.konteks,
    required this.pilihan,
    required this.jawabanBenar,
  });

  /// Label ringkas untuk ditampilkan di tabel
  String get labelLengkap =>
      'Part $noPart · No.$noSoal — ${dimensi.label} ${format.label}';

  factory SoalSternberg.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final noPart = (d['noPart'] as num?)?.toInt() ?? 1;
    final part = StatPart.fromNoPart(noPart);
    final rawPilihan = (d['pilihan'] as List<dynamic>? ?? [])
        .map((e) => PilihanJawaban.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return SoalSternberg(
      docId: doc.id,
      noSoal: (d['noSoal'] as num?)?.toInt() ?? 1,
      noPart: noPart,
      dimensi: part.dimensi,
      format: part.format,
      pernyataan: d['pernyataan'] as String? ?? '',
      gambarSoalUrl: d['gambarSoalUrl'] as String?,
      konteks: d['konteks'] as String?,
      pilihan: rawPilihan,
      jawabanBenar: d['jawabanBenar'] as String? ?? 'A',
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'noSoal': noSoal,
      'noPart': noPart,
      'dimensi': dimensi.firestoreValue,
      'format': format.firestoreValue,
      'pernyataan': pernyataan,
      'jawabanBenar': jawabanBenar,
      // List pilihan — pastikan tidak ada null di dalamnya
      'pilihan': pilihan.map((p) => p.toMap()).toList(),
    };
    // Field opsional — hanya masukkan jika tidak null DAN tidak kosong
    if (gambarSoalUrl != null && gambarSoalUrl!.isNotEmpty) {
      map['gambarSoalUrl'] = gambarSoalUrl;
    }
    if (konteks != null && konteks!.isNotEmpty) {
      map['konteks'] = konteks;
    }
    return map;
  }

  SoalSternberg copyWith({
    String? docId,
    int? noSoal,
    int? noPart,
    DimensiSternberg? dimensi,
    FormatKonten? format,
    String? pernyataan,
    String? gambarSoalUrl,
    String? konteks,
    List<PilihanJawaban>? pilihan,
    String? jawabanBenar,
  }) {
    final resolvedNoPart = noPart ?? this.noPart;
    final part = StatPart.fromNoPart(resolvedNoPart);
    return SoalSternberg(
      docId: docId ?? this.docId,
      noSoal: noSoal ?? this.noSoal,
      noPart: resolvedNoPart,
      dimensi: dimensi ?? part.dimensi,
      format: format ?? part.format,
      pernyataan: pernyataan ?? this.pernyataan,
      gambarSoalUrl: gambarSoalUrl ?? this.gambarSoalUrl,
      konteks: konteks ?? this.konteks,
      pilihan: pilihan ?? this.pilihan,
      jawabanBenar: jawabanBenar ?? this.jawabanBenar,
    );
  }
}

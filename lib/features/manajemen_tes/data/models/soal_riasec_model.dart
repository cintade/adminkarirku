import 'package:cloud_firestore/cloud_firestore.dart';

/// Metode soal RIASEC
enum MetodeSoal {
  pairedComparison, // Perbandingan berpasangan (A vs B)
  likert, // Skala Likert 1-5
}

extension MetodeSoalExt on MetodeSoal {
  String get label {
    switch (this) {
      case MetodeSoal.pairedComparison:
        return 'Paired Comparison';
      case MetodeSoal.likert:
        return 'Skala Likert';
    }
  }

  String get firestoreValue {
    switch (this) {
      case MetodeSoal.pairedComparison:
        return 'paired';
      case MetodeSoal.likert:
        return 'likert';
    }
  }

  static MetodeSoal fromString(String? val) {
    if (val == 'likert') return MetodeSoal.likert;
    return MetodeSoal.pairedComparison;
  }
}

// ─── Model Soal RIASEC ────────────────────────────────────────────────────────
class SoalRiasec {
  final String? docId;
  final int no;
  final MetodeSoal metode;

  // ── Field Paired Comparison ──────────────────────────────────────────────
  final String pernyataanA;
  final String tipeA; // R / I / A / S / E / C
  final String pernyataanB;
  final String tipeB;

  // ── Field Skala Likert ───────────────────────────────────────────────────
  final String pernyataan; // 1 pernyataan saja
  final String tipe; // R / I / A / S / E / C
  // Skala 1=Sangat Tidak Setuju s/d 5=Sangat Setuju
  // jawaban disimpan di sisi mobile

  const SoalRiasec({
    this.docId,
    required this.no,
    this.metode = MetodeSoal.pairedComparison,
    // Paired
    this.pernyataanA = '',
    this.tipeA = '',
    this.pernyataanB = '',
    this.tipeB = '',
    // Likert
    this.pernyataan = '',
    this.tipe = '',
  });

  factory SoalRiasec.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final metode = MetodeSoalExt.fromString(d['metode'] as String?);
    return SoalRiasec(
      docId: doc.id,
      no: (d['no'] as num?)?.toInt() ?? 0,
      metode: metode,
      // Paired
      pernyataanA: d['pernyataanA'] as String? ?? '',
      tipeA: d['tipeA'] as String? ?? '',
      pernyataanB: d['pernyataanB'] as String? ?? '',
      tipeB: d['tipeB'] as String? ?? '',
      // Likert
      pernyataan: d['pernyataan'] as String? ?? '',
      tipe: d['tipe'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    final base = <String, dynamic>{
      'no': no,
      'metode': metode.firestoreValue,
    };
    if (metode == MetodeSoal.pairedComparison) {
      base.addAll({
        'pernyataanA': pernyataanA,
        'tipeA': tipeA,
        'pernyataanB': pernyataanB,
        'tipeB': tipeB,
      });
    } else {
      base.addAll({
        'pernyataan': pernyataan,
        'tipe': tipe,
      });
    }
    return base;
  }

  SoalRiasec copyWith({
    String? docId,
    int? no,
    MetodeSoal? metode,
    String? pernyataanA,
    String? tipeA,
    String? pernyataanB,
    String? tipeB,
    String? pernyataan,
    String? tipe,
  }) {
    return SoalRiasec(
      docId: docId ?? this.docId,
      no: no ?? this.no,
      metode: metode ?? this.metode,
      pernyataanA: pernyataanA ?? this.pernyataanA,
      tipeA: tipeA ?? this.tipeA,
      pernyataanB: pernyataanB ?? this.pernyataanB,
      tipeB: tipeB ?? this.tipeB,
      pernyataan: pernyataan ?? this.pernyataan,
      tipe: tipe ?? this.tipe,
    );
  }
}

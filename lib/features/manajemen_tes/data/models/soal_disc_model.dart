import 'package:cloud_firestore/cloud_firestore.dart';

/// Dimensi DISC
enum DimensiDisc { dominance, influence, steadiness, conscientiousness }

extension DimensiDiscExt on DimensiDisc {
  String get label {
    switch (this) {
      case DimensiDisc.dominance:
        return 'Dominance (D)';
      case DimensiDisc.influence:
        return 'Influence (I)';
      case DimensiDisc.steadiness:
        return 'Steadiness (S)';
      case DimensiDisc.conscientiousness:
        return 'Conscientiousness (C)';
    }
  }

  String get singkatan {
    switch (this) {
      case DimensiDisc.dominance:
        return 'D';
      case DimensiDisc.influence:
        return 'I';
      case DimensiDisc.steadiness:
        return 'S';
      case DimensiDisc.conscientiousness:
        return 'C';
    }
  }

  String get firestoreValue {
    switch (this) {
      case DimensiDisc.dominance:
        return 'D';
      case DimensiDisc.influence:
        return 'I';
      case DimensiDisc.steadiness:
        return 'S';
      case DimensiDisc.conscientiousness:
        return 'C';
    }
  }

  static DimensiDisc fromString(String? val) {
    switch (val) {
      case 'I':
        return DimensiDisc.influence;
      case 'S':
        return DimensiDisc.steadiness;
      case 'C':
        return DimensiDisc.conscientiousness;
      default:
        return DimensiDisc.dominance;
    }
  }
}

/// Satu kata sifat dalam satu soal DISC
/// Setiap soal berisi 4 kata sifat, masing2 mewakili dimensi D/I/S/C
class KataSifatDisc {
  final String teks;
  final DimensiDisc dimensi; // kata ini mewakili dimensi apa

  const KataSifatDisc({required this.teks, required this.dimensi});

  factory KataSifatDisc.fromMap(Map<String, dynamic> map) => KataSifatDisc(
        teks: map['teks'] ?? '',
        dimensi: DimensiDiscExt.fromString(map['dimensi'] as String?),
      );

  Map<String, dynamic> toMap() => {
        'teks': teks,
        'dimensi': dimensi.firestoreValue,
      };
}

// ─── Model Soal DISC ──────────────────────────────────────────────────────────
/// Format Most & Least:
/// - Mahasiswa memilih 1 kata yang PALING menggambarkan dirinya (most)
/// - Mahasiswa memilih 1 kata yang PALING TIDAK menggambarkan dirinya (least)
/// - Setiap soal berisi tepat 4 [KataSifatDisc] (D, I, S, C)
class SoalDisc {
  final String? docId;
  final int no;

  /// 4 kata sifat, idealnya 1 per dimensi D/I/S/C
  final List<KataSifatDisc> kataSifat;

  const SoalDisc({
    this.docId,
    required this.no,
    required this.kataSifat,
  });

  factory SoalDisc.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawKata = (d['kataSifat'] as List<dynamic>? ?? [])
        .map((e) => KataSifatDisc.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return SoalDisc(
      docId: doc.id,
      no: (d['no'] as num?)?.toInt() ?? 0,
      kataSifat: rawKata,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'no': no,
        'kataSifat': kataSifat.map((k) => k.toMap()).toList(),
      };

  SoalDisc copyWith({
    String? docId,
    int? no,
    List<KataSifatDisc>? kataSifat,
  }) =>
      SoalDisc(
        docId: docId ?? this.docId,
        no: no ?? this.no,
        kataSifat: kataSifat ?? this.kataSifat,
      );
}

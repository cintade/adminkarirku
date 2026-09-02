import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enum RIASEC ─────────────────────────────────────────────────────────
// warnaHex dipakai UI untuk memberi warna beda ke tiap tipe (chip/badge).
enum TipeRiasec {
  R('R', 'Realistic', '🔧', 0xFFE67E22),
  I('I', 'Investigative', '🔬', 0xFF3498DB),
  A('A', 'Artistic', '🎨', 0xFF9B59B6),
  S('S', 'Social', '🤝', 0xFF2ECC71),
  E('E', 'Enterprising', '💼', 0xFFE74C3C),
  C('C', 'Conventional', '📊', 0xFF16A085);

  final String kode;
  final String label;
  final String emoji;
  final int warnaHex;
  const TipeRiasec(this.kode, this.label, this.emoji, this.warnaHex);

  static TipeRiasec fromString(String? val) {
    return TipeRiasec.values.firstWhere(
      (e) => e.kode == val,
      orElse: () => TipeRiasec.R,
    );
  }
}

// ─── Enum DISC ────────────────────────────────────────────────────────────
enum TipeDisc {
  D('D', 'Dominance', 0xFFE74C3C),
  I('I', 'Influence', 0xFFF39C12),
  S('S', 'Steadiness', 0xFF2ECC71),
  C('C', 'Conscientiousness', 0xFF3498DB);

  final String kode;
  final String label;
  final int warnaHex;
  const TipeDisc(this.kode, this.label, this.warnaHex);

  static TipeDisc fromString(String? val) {
    return TipeDisc.values.firstWhere(
      (e) => e.kode == val,
      orElse: () => TipeDisc.D,
    );
  }
}

// ─── Enum Kategori Bakat (dari Sternberg STAT) ─────────────────────────────
enum KategoriBakat {
  analitis('analitis', 'Analitis', '🧠', 0xFF3498DB),
  kreatif('kreatif', 'Kreatif', '💡', 0xFF9B59B6),
  praktis('praktis', 'Praktis', '⚙️', 0xFFE67E22);

  final String kode;
  final String label;
  final String emoji;
  final int warnaHex;
  const KategoriBakat(this.kode, this.label, this.emoji, this.warnaHex);

  static KategoriBakat fromString(String? val) {
    return KategoriBakat.values.firstWhere(
      (e) => e.kode == val,
      orElse: () => KategoriBakat.analitis,
    );
  }
}

// ─── Enum Jenjang Pendidikan ────────────────────────────────────────────────
enum JenjangPendidikan {
  d3('D3', 'Diploma 3'),
  s1('S1', 'Sarjana (S1)'),
  s2('S2', 'Magister (S2)'),
  semua('Semua', 'Semua Jenjang');

  final String kode;
  final String label;
  const JenjangPendidikan(this.kode, this.label);

  static JenjangPendidikan fromString(String? val) {
    return JenjangPendidikan.values.firstWhere(
      (e) => e.kode == val,
      orElse: () => JenjangPendidikan.semua,
    );
  }
}

// ─── Model Aturan Rekomendasi ───────────────────────────────────────────────
// Ini adalah representasi dari rule IF-THEN:
// JIKA (tipe_riasec = riasecDominan1 ATAU riasecDominan2, keduanya dominan)
// DAN tipe_disc = Y DAN kategori_bakat = Z DAN jenjang_pendidikan = W
// MAKA rekomendasikan karir (kr_id) dengan prioritas tertentu.
//
// Catatan perubahan: sebelumnya hanya 1 tipe RIASEC per aturan. Sekarang
// pakai 2 tipe dominan (mis. kombinasi Holland Code "RI", "SA", dst), karena
// di praktiknya skor tes RIASEC siswa jarang tunggal — biasanya ada 2 tipe
// teratas yang berdekatan skornya.
//
// Relasi: satu karir (kr_id) bisa punya banyak aturan_rekomendasi
// (1 karir : N aturan).
class AturanRekomendasiModel {
  final String? docId; // -> id
  final String krId; // -> kr_id (foreign key ke collection 'karir')
  final TipeRiasec riasecDominan1; // -> riasec_dominan_1
  final TipeRiasec riasecDominan2; // -> riasec_dominan_2
  final TipeDisc tipeDisc; // -> tipe_disc
  final KategoriBakat kategoriBakat; // -> kategori_bakat
  final JenjangPendidikan jenjangPendidikan; // -> jenjang_pendidikan
  final int prioritasRekomendasi; // -> prioritas_rekomendasi (1 = tertinggi)

  AturanRekomendasiModel({
    this.docId,
    required this.krId,
    required this.riasecDominan1,
    required this.riasecDominan2,
    required this.tipeDisc,
    required this.kategoriBakat,
    this.jenjangPendidikan = JenjangPendidikan.semua,
    this.prioritasRekomendasi = 1,
  }) : assert(
          riasecDominan1 != riasecDominan2,
          'riasecDominan1 dan riasecDominan2 harus dua tipe yang berbeda',
        );

  // Kode gabungan diurutkan alfabetis (mis. I + R -> "IR"), dipakai untuk
  // query pencocokan yang tidak peduli urutan input, dan untuk ditampilkan
  // sebagai "kode Holland" di UI.
  String get kodePasangan {
    final list = [riasecDominan1.kode, riasecDominan2.kode]..sort();
    return list.join();
  }

  factory AturanRekomendasiModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Kompatibilitas mundur: dokumen lama hanya menyimpan 1 field
    // 'tipe_riasec' tunggal. Jika field baru belum ada, field lama dipakai
    // sebagai riasecDominan1, dan riasecDominan2 diisi tipe lain sebagai
    // penampung sementara — sebaiknya dokumen ini dibuka & disimpan ulang
    // lewat form edit supaya field barunya lengkap.
    TipeRiasec dominan1;
    TipeRiasec dominan2;
    if (d['riasec_dominan_1'] != null && d['riasec_dominan_2'] != null) {
      dominan1 = TipeRiasec.fromString(d['riasec_dominan_1']);
      dominan2 = TipeRiasec.fromString(d['riasec_dominan_2']);
    } else {
      dominan1 = TipeRiasec.fromString(d['tipe_riasec']);
      dominan2 = TipeRiasec.values.firstWhere((t) => t != dominan1);
    }

    return AturanRekomendasiModel(
      docId: doc.id,
      krId: d['kr_id'] ?? '',
      riasecDominan1: dominan1,
      riasecDominan2: dominan2,
      tipeDisc: TipeDisc.fromString(d['tipe_disc']),
      kategoriBakat: KategoriBakat.fromString(d['kategori_bakat']),
      jenjangPendidikan: JenjangPendidikan.fromString(d['jenjang_pendidikan']),
      prioritasRekomendasi: (d['prioritas_rekomendasi'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kr_id': krId,
      'riasec_dominan_1': riasecDominan1.kode,
      'riasec_dominan_2': riasecDominan2.kode,
      'riasec_pasangan': kodePasangan, // untuk query tanpa peduli urutan
      'tipe_disc': tipeDisc.kode,
      'kategori_bakat': kategoriBakat.kode,
      'jenjang_pendidikan': jenjangPendidikan.kode,
      'prioritas_rekomendasi': prioritasRekomendasi,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  AturanRekomendasiModel copyWith({
    String? docId,
    String? krId,
    TipeRiasec? riasecDominan1,
    TipeRiasec? riasecDominan2,
    TipeDisc? tipeDisc,
    KategoriBakat? kategoriBakat,
    JenjangPendidikan? jenjangPendidikan,
    int? prioritasRekomendasi,
  }) {
    return AturanRekomendasiModel(
      docId: docId ?? this.docId,
      krId: krId ?? this.krId,
      riasecDominan1: riasecDominan1 ?? this.riasecDominan1,
      riasecDominan2: riasecDominan2 ?? this.riasecDominan2,
      tipeDisc: tipeDisc ?? this.tipeDisc,
      kategoriBakat: kategoriBakat ?? this.kategoriBakat,
      jenjangPendidikan: jenjangPendidikan ?? this.jenjangPendidikan,
      prioritasRekomendasi: prioritasRekomendasi ?? this.prioritasRekomendasi,
    );
  }
}

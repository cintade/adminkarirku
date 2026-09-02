import 'package:cloud_firestore/cloud_firestore.dart';

/// Model tabel relasi Mata Kuliah <-> Karir.
/// Collection Firestore: "makukar" — SAMA dengan yang dipakai mobile app.
///
/// Konvensi mkk_prioritas: angka LEBIH BESAR = LEBIH RELEVAN/penting
/// (P5 = paling relevan, P1 = paling rendah), sesuai urutan tampilan
/// pada UI admin (P5 di atas, lalu P4, P3, dst).
class Makukar {
  final String mkkId;
  final String mkkMkId;
  final String mkkKrId;
  final int mkkPrioritas;
  final String mkkTipeFaktor;
  final String mkkKeterangan;

  Makukar({
    required this.mkkId,
    required this.mkkMkId,
    required this.mkkKrId,
    required this.mkkPrioritas,
    required this.mkkTipeFaktor,
    required this.mkkKeterangan,
  });

  factory Makukar.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Makukar(
      mkkId: doc.id,
      mkkMkId: data['mkk_mk_id'] ?? '',
      mkkKrId: data['mkk_kr_id'] ?? '',
      mkkPrioritas: data['mkk_prioritas'] is int
          ? data['mkk_prioritas']
          : int.tryParse('${data['mkk_prioritas']}') ?? 0,
      mkkTipeFaktor: data['mkk_tipe_faktor'] ?? '',
      mkkKeterangan: data['mkk_keterangan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mkk_mk_id': mkkMkId,
      'mkk_kr_id': mkkKrId,
      'mkk_prioritas': mkkPrioritas,
      'mkk_tipe_faktor': mkkTipeFaktor,
      'mkk_keterangan': mkkKeterangan,
    };
  }
}

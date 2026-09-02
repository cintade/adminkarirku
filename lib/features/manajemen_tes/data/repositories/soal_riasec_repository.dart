import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_riasec_model.dart';

class SoalRiasecRepository {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('soal_riasec');

  // ─── Stream ─────────────────────────────────────────────────────────────────

  /// Stream semua soal RIASEC — real-time, urut nomor
  Stream<List<SoalRiasec>> streamSoal() {
    return _col.orderBy('no').snapshots().map(
          (snap) => snap.docs.map((d) => SoalRiasec.fromFirestore(d)).toList(),
        );
  }

  /// Stream soal berdasarkan metode (paired / likert)
  Stream<List<SoalRiasec>> streamSoalByMetode(MetodeSoal metode) {
    return _col
        .where('metode', isEqualTo: metode.firestoreValue)
        .orderBy('no') // ← tambahkan ini
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => SoalRiasec.fromFirestore(d)).toList();
      list.sort((a, b) => a.no.compareTo(b.no)); // fallback sort client
      return list;
    });
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  /// Tambah soal baru
  Future<void> tambah(SoalRiasec soal) async {
    await _col.add(soal.toFirestore());
  }

  /// Update soal berdasarkan docId
  Future<void> update(String docId, SoalRiasec soal) async {
    await _col.doc(docId).update(soal.toFirestore());
  }

  /// Hapus soal berdasarkan docId
  Future<void> hapus(String docId) async {
    await _col.doc(docId).delete();
  }

  // ─── Count ───────────────────────────────────────────────────────────────────

  /// Hitung total semua soal RIASEC (untuk nomor otomatis)
  Future<int> countSoal() async {
    final snap = await _col.get();
    return snap.docs.length;
  }

  /// Hitung soal per metode
  Future<int> countByMetode(MetodeSoal metode) async {
    final snap =
        await _col.where('metode', isEqualTo: metode.firestoreValue).get();
    return snap.docs.length;
  }
}

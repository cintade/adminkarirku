import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_disc_model.dart';

class SoalDiscRepository {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('soal_disc');

  /// Stream semua soal — real-time, urut nomor
  Stream<List<SoalDisc>> streamSoal() {
    return _col.orderBy('no').snapshots().map(
          (snap) => snap.docs.map((d) => SoalDisc.fromFirestore(d)).toList(),
        );
  }

  /// Tambah soal baru
  Future<void> tambah(SoalDisc soal) async {
    await _col.add(soal.toFirestore());
  }

  /// Update soal
  Future<void> update(String docId, SoalDisc soal) async {
    await _col.doc(docId).update(soal.toFirestore());
  }

  /// Hapus soal
  Future<void> hapus(String docId) async {
    await _col.doc(docId).delete();
  }

  /// Hitung total soal
  Future<int> countSoal() async {
    final snap = await _col.get();
    return snap.docs.length;
  }
}

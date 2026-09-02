import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_sternberg_model.dart';

class SoalSternbergRepository {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('soal_sternberg');

  // ─── Stream ─────────────────────────────────────────────────────────────────

  Stream<List<SoalSternberg>> streamSoal() {
    return _col.orderBy('noPart').orderBy('noSoal').snapshots().map((snap) =>
        snap.docs.map((d) => SoalSternberg.fromFirestore(d)).toList());
  }

  Stream<List<SoalSternberg>> streamSoalByPart(int noPart) {
    return _col.where('noPart', isEqualTo: noPart).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => SoalSternberg.fromFirestore(d)).toList();
      list.sort((a, b) => a.noSoal.compareTo(b.noSoal));
      return list;
    });
  }

  Stream<List<SoalSternberg>> streamSoalByDimensi(DimensiSternberg dimensi) {
    return _col
        .where('dimensi', isEqualTo: dimensi.firestoreValue)
        .orderBy('noPart')
        .orderBy('noSoal')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SoalSternberg.fromFirestore(d)).toList());
  }

  Stream<List<SoalSternberg>> streamSoalByFormat(FormatKonten format) {
    return _col
        .where('format', isEqualTo: format.firestoreValue)
        .orderBy('noPart')
        .orderBy('noSoal')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => SoalSternberg.fromFirestore(d)).toList());
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> tambah(SoalSternberg soal) async {
    await _col.add(soal.toFirestore());
  }

  Future<void> update(String docId, SoalSternberg soal) async {
    await _col.doc(docId).update(soal.toFirestore());
  }

  Future<void> hapus(String docId) async {
    await _col.doc(docId).delete();
  }

  // ─── Count ───────────────────────────────────────────────────────────────────

  Future<int> countSoal() async {
    final snap = await _col.get();
    return snap.docs.length;
  }

  Future<int> countByPart(int noPart) async {
    final snap = await _col.where('noPart', isEqualTo: noPart).get();
    return snap.docs.length;
  }

  Future<int> countByDimensi(DimensiSternberg dimensi) async {
    final snap =
        await _col.where('dimensi', isEqualTo: dimensi.firestoreValue).get();
    return snap.docs.length;
  }

  Future<int> nextNoSoalInPart(int noPart) async {
    final snap = await FirebaseFirestore.instance
        .collection('soal_sternberg')
        .where('noPart', isEqualTo: noPart)
        .get(const GetOptions(source: Source.server));
    return snap.docs.length + 1;
  }

  Future<Map<int, int>> countPerPart() async {
    final snap = await FirebaseFirestore.instance
        .collection('soal_sternberg')
        .get(const GetOptions(source: Source.server));
    final Map<int, int> result = {for (int i = 1; i <= 9; i++) i: 0};
    for (final doc in snap.docs) {
      final d = doc.data();
      final noPart = (d['noPart'] as num?)?.toInt() ?? 1;
      result[noPart] = (result[noPart] ?? 0) + 1;
    }
    return result;
  }
}

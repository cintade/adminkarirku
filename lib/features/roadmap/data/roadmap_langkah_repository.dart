import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adminkarieku/features/roadmap/data/roadmap_langkah_model.dart';

class RoadmapLangkahRepository {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('roadmap_langkah');

  // ─── Stream ─────────────────────────────────────────────────────────────────

  /// Semua langkah — sort client-side, tidak butuh composite index
  Stream<List<RoadmapLangkah>> streamSemua() {
    return _col.snapshots().map((snap) {
      final list =
          snap.docs.map((d) => RoadmapLangkah.fromFirestore(d)).toList();
      list.sort((a, b) {
        final byKarir = a.karierId.compareTo(b.karierId);
        if (byKarir != 0) return byKarir;
        return a.urutan.compareTo(b.urutan);
      });
      return list;
    });
  }

  /// Langkah per karir — dipakai mobile
  Stream<List<RoadmapLangkah>> streamByKarir(String karierId) {
    return _col.where('karir_id', isEqualTo: karierId).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => RoadmapLangkah.fromFirestore(d)).toList();
      list.sort((a, b) => a.urutan.compareTo(b.urutan));
      return list;
    });
  }

  /// Ambil semua karir_id unik — untuk filter dropdown
  Future<List<String>> getKarirIds() async {
    final snap = await _col.get();
    final ids = snap.docs
        .map((d) => (d.data() as Map)['karir_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ids;
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> tambah(RoadmapLangkah langkah) async {
    await _col.add(langkah.toFirestore());
  }

  Future<void> update(String docId, RoadmapLangkah langkah) async {
    await _col.doc(docId).update(langkah.toFirestore());
  }

  Future<void> hapus(String docId) async {
    await _col.doc(docId).delete();
  }

  /// Nomor urutan berikutnya untuk karir tertentu
  Future<int> nextUrutan(String karierId) async {
    final snap = await _col.where('karir_id', isEqualTo: karierId).get();
    return snap.docs.length + 1;
  }

  /// Reorder urutan setelah drag/edit
  Future<void> reorder(List<RoadmapLangkah> list) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < list.length; i++) {
      if (list[i].docId != null) {
        batch.update(_col.doc(list[i].docId!), {'urutan': i + 1});
      }
    }
    await batch.commit();
  }
}

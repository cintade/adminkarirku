import 'package:cloud_firestore/cloud_firestore.dart';
import 'mata_kuliah_model.dart';

class MataKuliahRepository {
  final _col = FirebaseFirestore.instance.collection('mata_kuliah');

  // ── Ambil semua MK (FutureBuilder — bukan stream, hindari bug Firestore web)
  Future<List<MataKuliah>> getAll({
    int? semester,
    String? prodi,
    String? search,
  }) async {
    final snap = await _col.get();

    List<MataKuliah> list = snap.docs.map(MataKuliah.fromFirestore).toList();

    if (semester != null) {
      list = list.where((e) => e.mkSemester == semester).toList();
    }

    if (prodi != null && prodi.isNotEmpty) {
      list = list.where((e) => e.mkProdi == prodi).toList();
    }

    list.sort((a, b) {
      if (a.mkSemester != b.mkSemester) {
        return a.mkSemester.compareTo(b.mkSemester);
      }
      return a.mkId.compareTo(b.mkId);
    });

    // Filter search di client (Firestore tidak support full-text search)
    if (search != null && search.isNotEmpty) {
      final q2 = search.toLowerCase();
      list = list
          .where((mk) =>
              mk.mkId.toLowerCase().contains(q2) ||
              mk.mkNama.toLowerCase().contains(q2) ||
              mk.mkProdi.toLowerCase().contains(q2))
          .toList();
    }

    return list;
  }

  // ── Ambil daftar prodi unik ───────────────────────────────────────────────
  Future<List<String>> getProdiList() async {
    final snap = await _col.get();
    final set = <String>{};
    for (final doc in snap.docs) {
      final prodi = (doc.data()['mk_prodi'] as String?) ?? '';
      if (prodi.isNotEmpty) set.add(prodi);
    }
    final list = set.toList()..sort();
    return list;
  }

  // ── Hitung total MK ──────────────────────────────────────────────────────
  Future<int> countAll() async {
    final snap = await _col.count().get();
    return snap.count ?? 0;
  }

  // ── Tambah MK ────────────────────────────────────────────────────────────
  Future<void> tambah(MataKuliah mk) async {
    // Cek duplikat mk_id
    final existing =
        await _col.where('mk_id', isEqualTo: mk.mkId).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Kode MK "${mk.mkId}" sudah ada!');
    }
    await _col.add({
      ...mk.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Update MK ────────────────────────────────────────────────────────────
  Future<void> update(MataKuliah mk) async {
    if (mk.docId == null) return;

    // Cek duplikat mk_id (kecuali dokumen sendiri)
    final existing =
        await _col.where('mk_id', isEqualTo: mk.mkId).limit(2).get();
    final others = existing.docs.where((d) => d.id != mk.docId).toList();
    if (others.isNotEmpty) {
      throw Exception('Kode MK "${mk.mkId}" sudah digunakan!');
    }

    await _col.doc(mk.docId).update({
      ...mk.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Hapus MK ─────────────────────────────────────────────────────────────
  Future<void> hapus(String docId) async {
    await _col.doc(docId).delete();
  }

  // ── Import batch (dari Excel/CSV) ─────────────────────────────────────────
  Future<int> importBatch(List<MataKuliah> list) async {
    int sukses = 0;
    final batch = FirebaseFirestore.instance.batch();

    for (final mk in list) {
      final ref = _col.doc();
      batch.set(ref, {
        ...mk.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      sukses++;
    }

    await batch.commit();
    return sukses;
  }
}

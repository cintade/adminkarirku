import 'package:cloud_firestore/cloud_firestore.dart';
import 'karir_model.dart';

class KarirRepository {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('karir');

  // ─── Stream semua karir ──────────────────────────────────────────────────
  Stream<List<KarirModel>> streamKarir() {
    return _col.orderBy('nama').snapshots().map(
          (snap) => snap.docs.map((d) => KarirModel.fromFirestore(d)).toList(),
        );
  }

  // ─── Ambil satu karir (dipakai di form aturan_rekomendasi utk dropdown) ──
  Future<KarirModel?> getById(String docId) async {
    final doc = await _col.doc(docId).get();
    if (!doc.exists) return null;
    return KarirModel.fromFirestore(doc);
  }

  // ─── Tambah karir baru ───────────────────────────────────────────────────
  // customId opsional: kalau diisi, dokumen akan disimpan dengan ID tersebut
  // (misal "karir_software_engineer"). Kalau null/kosong, Firestore akan
  // generate auto-ID seperti biasa.
  Future<String> tambah(KarirModel karir, {String? customId}) async {
    try {
      if (customId != null && customId.trim().isNotEmpty) {
        final id = customId.trim();
        final existing = await _col.doc(id).get();
        if (existing.exists) {
          throw Exception('ID karir "$id" sudah dipakai, gunakan ID lain');
        }
        await _col.doc(id).set(karir.toFirestore());
        return id;
      } else {
        final ref = await _col.add(karir.toFirestore());
        return ref.id;
      }
    } catch (e) {
      throw Exception('Gagal menambah karir: $e');
    }
  }

  // ─── Cek apakah suatu Document ID sudah dipakai ──────────────────────────
  // Dipakai form untuk validasi real-time sebelum submit.
  Future<bool> cekIdTersedia(String id) async {
    if (id.trim().isEmpty) return false;
    final doc = await _col.doc(id.trim()).get();
    return !doc.exists;
  }

  // ─── Generate ID slug dari nama karir ────────────────────────────────────
  // Contoh: "Software Engineer" -> "karir_software_engineer"
  //         "UI/UX Designer"    -> "karir_ui_ux_designer"
  String generateIdDariNama(String nama) {
    final slug = nama
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // buang karakter aneh
        .replaceAll(RegExp(r'\s+'), '_'); // spasi -> underscore
    return slug.isEmpty ? 'karir_baru' : 'karir_$slug';
  }

  // ─── Update karir ────────────────────────────────────────────────────────
  Future<void> update(String docId, KarirModel karir) async {
    try {
      await _col.doc(docId).update(karir.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate karir: $e');
    }
  }

  // ─── Hapus karir ─────────────────────────────────────────────────────────
  // PENTING: karena aturan_rekomendasi punya kr_id yang mereferensikan karir
  // ini, semua aturan_rekomendasi yang terkait ikut dihapus (cascade manual,
  // Firestore tidak punya foreign key otomatis).
  Future<void> hapus(String docId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(_col.doc(docId));

      final aturanTerkait = await FirebaseFirestore.instance
          .collection('aturan_rekomendasi')
          .where('kr_id', isEqualTo: docId)
          .get();
      for (final doc in aturanTerkait.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal menghapus karir: $e');
    }
  }

  // ─── Ambil semua MK dari koleksi mata_kuliah (untuk dropdown) ────────────
  Future<List<String>> getDaftarMK() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('mata_kuliah').get();
      return snap.docs
          .map((d) => (d.data()['mk_nama'] ?? d.data()['nama'] ?? '') as String)
          .where((nama) => nama.isNotEmpty)
          .toList()
        ..sort();
    } catch (e) {
      return [];
    }
  }

  // ─── Ambil daftar karir (id + nama) untuk dropdown di aturan_rekomendasi ─
  Future<List<Map<String, String>>> getDaftarKarirRingkas() async {
    final snap = await _col.orderBy('nama').get();
    return snap.docs
        .map((d) => {
              'id': d.id,
              'nama': (d.data() as Map<String, dynamic>)['nama'] as String? ??
                  '(tanpa nama)',
            })
        .toList();
  }
}

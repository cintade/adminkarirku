import 'package:cloud_firestore/cloud_firestore.dart';
import 'aturan_rekomendasi_model.dart';

class AturanRekomendasiRepository {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('aturan_rekomendasi');

  // ─── Stream semua aturan (urut berdasarkan prioritas) ───────────────────
  Stream<List<AturanRekomendasiModel>> streamSemua() {
    return _col.orderBy('prioritas_rekomendasi').snapshots().map(
          (snap) => snap.docs
              .map((d) => AturanRekomendasiModel.fromFirestore(d))
              .toList(),
        );
  }

  // ─── Stream aturan untuk 1 karir tertentu ────────────────────────────────
  // Sort prioritas dilakukan di client (bukan .orderBy() di server) supaya
  // tidak butuh composite index gabungan where+orderBy di Firestore.
  Stream<List<AturanRekomendasiModel>> streamByKarir(String krId) {
    return _col.where('kr_id', isEqualTo: krId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AturanRekomendasiModel.fromFirestore(d))
          .toList();
      list.sort(
          (a, b) => a.prioritasRekomendasi.compareTo(b.prioritasRekomendasi));
      return list;
    });
  }

  // ─── Cari aturan yang cocok dengan hasil tes siswa ───────────────────────
  // Dipakai oleh sisi aplikasi mobile untuk mesin rekomendasi rule-based.
  //
  // riasecDominan1 & riasecDominan2 boleh dikirim dalam urutan apa pun (mis.
  // hasil skor tertinggi siswa "I lalu R", atau sebaliknya) — pencocokan
  // dilakukan lewat field 'riasec_pasangan' yang sudah diurutkan alfabetis
  // saat disimpan, jadi urutan input di sini tidak berpengaruh ke hasil.
  Future<List<AturanRekomendasiModel>> cariAturanCocok({
    required TipeRiasec riasecDominan1,
    required TipeRiasec riasecDominan2,
    required TipeDisc disc,
    required KategoriBakat bakat,
    JenjangPendidikan? jenjang,
  }) async {
    final pasangan =
        ([riasecDominan1.kode, riasecDominan2.kode]..sort()).join();

    // Catatan: sengaja TIDAK pakai .orderBy() di query gabungan dengan
    // banyak .where() ini, supaya tidak butuh composite index baru di
    // Firestore (lih. riwayat error composite index sebelumnya di project
    // ini). Urutan prioritas di-sort manual di client setelah data didapat.
    Query q = _col
        .where('riasec_pasangan', isEqualTo: pasangan)
        .where('tipe_disc', isEqualTo: disc.kode)
        .where('kategori_bakat', isEqualTo: bakat.kode);

    final snap = await q.get();
    var hasil =
        snap.docs.map((d) => AturanRekomendasiModel.fromFirestore(d)).toList();

    if (jenjang != null) {
      hasil = hasil
          .where((a) =>
              a.jenjangPendidikan == jenjang ||
              a.jenjangPendidikan == JenjangPendidikan.semua)
          .toList();
    }
    hasil.sort(
        (a, b) => a.prioritasRekomendasi.compareTo(b.prioritasRekomendasi));
    return hasil;
  }

  // ─── Tambah aturan baru ──────────────────────────────────────────────────
  Future<void> tambah(AturanRekomendasiModel aturan) async {
    try {
      await _col.add(aturan.toFirestore());
    } catch (e) {
      throw Exception('Gagal menambah aturan rekomendasi: $e');
    }
  }

  // ─── Update aturan ────────────────────────────────────────────────────────
  Future<void> update(String docId, AturanRekomendasiModel aturan) async {
    try {
      await _col.doc(docId).update(aturan.toFirestore());
    } catch (e) {
      throw Exception('Gagal mengupdate aturan rekomendasi: $e');
    }
  }

  // ─── Hapus aturan ─────────────────────────────────────────────────────────
  Future<void> hapus(String docId) async {
    try {
      await _col.doc(docId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus aturan rekomendasi: $e');
    }
  }

  // ─── Migrasi data lama (opsional, jalankan sekali) ───────────────────────
  // Dokumen lama yang hanya punya field 'tipe_riasec' tunggal tidak akan
  // ketemu lewat cariAturanCocok() karena belum punya 'riasec_pasangan'.
  // Panggil fungsi ini sekali (mis. dari tombol admin tersembunyi) untuk
  // menulis ulang semua dokumen lama supaya field barunya terisi.
  Future<int> migrasiKeRiasecGanda() async {
    final snap = await _col.get();
    var jumlahDiupdate = 0;
    for (final doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['riasec_pasangan'] == null) {
        final model = AturanRekomendasiModel.fromFirestore(doc);
        await _col.doc(doc.id).update(model.toFirestore());
        jumlahDiupdate++;
      }
    }
    return jumlahDiupdate;
  }
}

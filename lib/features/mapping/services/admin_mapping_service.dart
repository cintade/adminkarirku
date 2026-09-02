import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mata_kuliah_model.dart';
import '../models/karir_model.dart';

/// Service untuk fitur "Mapping MK — Profesi" di admin web.
///
/// PENTING — disesuaikan dengan struktur data ASLI di Firestore:
/// TIDAK ADA collection relasi terpisah seperti "makukar". Hubungan
/// Karir <-> Mata Kuliah disimpan langsung di field `mk_pendukung`
/// (array nama mata kuliah) pada setiap dokumen karir. Urutan di
/// dalam array tersebut dipakai sebagai prioritas (index 0 = paling
/// relevan).
class AdminMappingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String collMataKuliah = 'mata_kuliah';
  static const String collKarir = 'karir';

  // ---------- Data referensi untuk dropdown ----------
  Future<List<MataKuliah>> getAllMataKuliah() async {
    final snap = await _db.collection(collMataKuliah).orderBy('mk_nama').get();
    return snap.docs.map((d) => MataKuliah.fromFirestore(d)).toList();
  }

  Future<List<Karir>> getAllKarir() async {
    final snap = await _db.collection(collKarir).orderBy('nama').get();
    return snap.docs.map((d) => Karir.fromFirestore(d)).toList();
  }

  /// Cari satu dokumen mata_kuliah berdasarkan NAMA persis (karena
  /// mk_pendukung menyimpan nama, bukan mk_id).
  Future<MataKuliah?> getMataKuliahByNama(String nama) async {
    final snap = await _db
        .collection(collMataKuliah)
        .where('mk_nama', isEqualTo: nama)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MataKuliah.fromFirestore(snap.docs.first);
  }

  // ---------- Panel kiri: "Dari Mata Kuliah" ----------
  /// Cari semua karir yang menyebut [mkNama] di dalam field mk_pendukung.
  /// Prioritas dihitung dari posisi dalam array (semakin awal = makin besar).
  Future<List<MapEntry<Karir, int>>> getKarirByMkNama(String mkNama) async {
    final snap = await _db
        .collection(collKarir)
        .where('mk_pendukung', arrayContains: mkNama)
        .get();

    final result = <MapEntry<Karir, int>>[];
    for (final doc in snap.docs) {
      final karir = Karir.fromFirestore(doc);
      final idx = karir.mkPendukung.indexOf(mkNama);
      final priority = karir.mkPendukung.length - idx;
      result.add(MapEntry(karir, priority));
    }
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  // ---------- Panel kanan: "Dari Profesi" ----------
  /// Ambil detail mata kuliah pendukung dari satu karir, sesuai urutan
  /// asli di array (urutan = prioritas, item pertama paling penting).
  Future<List<MapEntry<MataKuliah?, int>>> getMkPendukungDetail(
      Karir karir) async {
    final result = <MapEntry<MataKuliah?, int>>[];
    for (int i = 0; i < karir.mkPendukung.length; i++) {
      final nama = karir.mkPendukung[i];
      final mk = await getMataKuliahByNama(nama);
      final priority = karir.mkPendukung.length - i;
      result.add(MapEntry(mk, priority));
    }
    return result;
  }

  // ---------- Tambah / Hapus / Reorder mk_pendukung ----------

  /// Tambah satu nama mata kuliah ke field mk_pendukung milik [karirId].
  /// Ditambahkan di akhir array (prioritas terendah secara default).
  Future<void> addMkPendukung(String karirId, String mkNama) async {
    await _db.collection(collKarir).doc(karirId).update({
      'mk_pendukung': FieldValue.arrayUnion([mkNama]),
    });
  }

  /// Hapus satu nama mata kuliah dari mk_pendukung milik [karirId].
  Future<void> removeMkPendukung(String karirId, String mkNama) async {
    await _db.collection(collKarir).doc(karirId).update({
      'mk_pendukung': FieldValue.arrayRemove([mkNama]),
    });
  }

  /// Timpa seluruh urutan mk_pendukung sekaligus — dipakai untuk
  /// menggeser prioritas (pindah ke atas/bawah).
  Future<void> setMkPendukungOrder(
      String karirId, List<String> orderedNama) async {
    await _db.collection(collKarir).doc(karirId).update({
      'mk_pendukung': orderedNama,
    });
  }

  // ---------- CRUD data master Karir (form "Tambah/Edit Karir") ----------

  /// Buat dokumen karir baru. [data] berisi field: nama, deskripsi, emoji,
  /// sternberg, riasec, disc, skill_utama, mk_pendukung — sesuai struktur
  /// data asli (lihat karir_model.dart). jumlah_mahasiswa & rata_rata_kesiapan
  /// di-set 0 karena dihitung otomatis oleh proses lain (hasil tes), bukan
  /// diisi manual lewat form ini.
  Future<void> addKarir(Map<String, dynamic> data) async {
    await _db.collection(collKarir).add({
      ...data,
      'jumlah_mahasiswa': 0,
      'rata_rata_kesiapan': 0,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Update dokumen karir yang sudah ada. jumlah_mahasiswa & rata_rata_kesiapan
  /// TIDAK ikut ditimpa (tidak ada di [data]) supaya nilai yang sudah dihitung
  /// sistem tidak hilang saat admin edit info dasar karir.
  Future<void> updateKarir(String karirId, Map<String, dynamic> data) async {
    await _db.collection(collKarir).doc(karirId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteKarir(String karirId) async {
    await _db.collection(collKarir).doc(karirId).delete();
  }
}

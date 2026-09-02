import 'package:cloud_firestore/cloud_firestore.dart';
import 'mahasiswa_model.dart';

/// Ringkasan status tes satu mahasiswa, dihitung dari keberadaan
/// dokumen di hasil_riasec/{uid}, hasil_disc/{uid}, hasil_bakat/{uid}.
class RingkasanTes {
  final String riasecDominant; // dari field `tipe_dominan` di hasil_riasec
  final String statusTes; // Lengkap | Sebagian | Belum
  final double kesiapanPercentage;

  RingkasanTes({
    required this.riasecDominant,
    required this.statusTes,
    required this.kesiapanPercentage,
  });
}

/// Service untuk komunikasi dengan data mahasiswa di Firestore.
///
/// PENTING: data profil mahasiswa TERNYATA disimpan di collection
/// `users` (bukan `mahasiswa`), dengan field firstName/lastName/
/// studyProgram/semester(string). Lihat MahasiswaModel.fromFirestore
/// untuk detail mapping-nya.
///
/// Kita sengaja TIDAK memakai `.where()` + `.orderBy()` gabungan di sisi
/// Firestore supaya tidak perlu membuat composite index (konsisten
/// dengan pola yang sudah dipakai di modul lain KarirKu). Filter
/// (prodi/semester/status) dan sorting dilakukan di client, setelah
/// data di-stream dari Firestore.
class MahasiswaService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('users');
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream seluruh data mahasiswa, sudah terurut berdasarkan nama.
  Stream<List<MahasiswaModel>> streamMahasiswa() {
    return _col.snapshots().map((snapshot) {
      final list =
          snapshot.docs.map((d) => MahasiswaModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
      return list;
    });
  }

  /// Ambil ringkasan status tes 1 mahasiswa, dengan mengecek keberadaan
  /// dokumen hasil_riasec/{uid}, hasil_disc/{uid}, hasil_bakat/{uid}
  /// secara paralel (3 get request, bukan realtime listener — supaya
  /// hemat dan cukup untuk tabel yang tidak perlu update tiap detik).
  Future<RingkasanTes> ambilRingkasanTes(String uid) async {
    final hasil = await Future.wait([
      _db.collection('hasil_riasec').doc(uid).get(),
      _db.collection('hasil_disc').doc(uid).get(),
      _db.collection('hasil_bakat').doc(uid).get(),
    ]);

    final docRiasec = hasil[0];
    final selesaiCount = hasil.where((d) => d.exists).length;

    String status;
    if (selesaiCount == 3) {
      status = 'Lengkap';
    } else if (selesaiCount == 0) {
      status = 'Belum';
    } else {
      status = 'Sebagian';
    }

    String riasecDominant = '-';
    if (docRiasec.exists) {
      final data = docRiasec.data() as Map<String, dynamic>?;
      riasecDominant = (data?['tipe_dominan'] ?? '-') as String;
    }

    return RingkasanTes(
      riasecDominant: riasecDominant,
      statusTes: status,
      kesiapanPercentage: (selesaiCount / 3) * 100,
    );
  }

  Future<void> tambahMahasiswa(MahasiswaModel mhs) async {
    await _col.add(mhs.toMap());
  }

  Future<void> hapusMahasiswa(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> updateMahasiswa(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update(data);
  }
}

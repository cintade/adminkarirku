import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data Karir — disesuaikan dengan struktur ASLI di Firestore
/// project KarierKu (collection "karir").
///
/// PENTING: tidak ada collection relasi terpisah seperti "makukar".
/// Hubungan Karir <-> Mata Kuliah disimpan LANGSUNG di field
/// [mkPendukung] sebagai array nama mata kuliah (bukan ID).
/// Urutan di dalam array ini dipakai sebagai PRIORITAS — index 0
/// (item pertama) dianggap paling relevan/penting.
class Karir {
  final String
      karirId; // Firestore Document ID (tidak ada field karir_id terpisah)
  final String nama;
  final String deskripsi;
  final String emoji;
  final List<String> disc;
  final List<String> riasec;
  final String sternberg;
  final List<String> skillUtama;
  final int jumlahMahasiswa;
  final int rataRataKesiapan;
  final List<String> mkPendukung;

  Karir({
    required this.karirId,
    required this.nama,
    required this.deskripsi,
    required this.emoji,
    required this.disc,
    required this.riasec,
    required this.sternberg,
    required this.skillUtama,
    required this.jumlahMahasiswa,
    required this.rataRataKesiapan,
    required this.mkPendukung,
  });

  factory Karir.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Karir(
      karirId: doc.id,
      nama: data['nama'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      emoji: data['emoji'] ?? '',
      disc: List<String>.from(data['disc'] ?? const []),
      riasec: List<String>.from(data['riasec'] ?? const []),
      sternberg: data['sternberg'] ?? '',
      skillUtama: List<String>.from(data['skill_utama'] ?? const []),
      jumlahMahasiswa: data['jumlah_mahasiswa'] is int
          ? data['jumlah_mahasiswa']
          : int.tryParse('${data['jumlah_mahasiswa']}') ?? 0,
      rataRataKesiapan: data['rata_rata_kesiapan'] is int
          ? data['rata_rata_kesiapan']
          : int.tryParse('${data['rata_rata_kesiapan']}') ?? 0,
      mkPendukung: List<String>.from(data['mk_pendukung'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'deskripsi': deskripsi,
      'emoji': emoji,
      'disc': disc,
      'riasec': riasec,
      'sternberg': sternberg,
      'skill_utama': skillUtama,
      'jumlah_mahasiswa': jumlahMahasiswa,
      'rata_rata_kesiapan': rataRataKesiapan,
      'mk_pendukung': mkPendukung,
    };
  }
}

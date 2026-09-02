// ══════════════════════════════════════════════════════════════
// LAPORAN MODEL
// Data yang dikumpulkan dari Firestore untuk halaman Laporan Admin
// ══════════════════════════════════════════════════════════════

/// Ringkasan statistik utama (4 kartu di atas halaman).
class LaporanOverviewModel {
  /// % mahasiswa yang sudah selesai ketiga tes (RIASEC + DISC + Bakat)
  final double tingkatPenyelesaianTes;

  /// Perubahan % vs bulan lalu (positif = naik, negatif = turun)
  final double deltaVsBulanLalu;

  /// Jumlah mahasiswa yang pernah login minimal sekali dalam 30 hari terakhir
  final int mahasiswaAktif;

  /// % mahasiswa aktif dari total terdaftar
  final double persenMahasiswaAktif;

  /// Jumlah roadmap yang sudah diselesaikan seluruh mahasiswa
  final int roadmapSelesai;

  /// % dari total langkah roadmap yang ada
  final double persenRoadmapSelesai;

  /// Rata-rata waktu mengerjakan satu sesi tes (menit)
  final double waktuRataRataTes;

  /// Total mahasiswa terdaftar
  final int totalMahasiswa;

  const LaporanOverviewModel({
    required this.tingkatPenyelesaianTes,
    required this.deltaVsBulanLalu,
    required this.mahasiswaAktif,
    required this.persenMahasiswaAktif,
    required this.roadmapSelesai,
    required this.persenRoadmapSelesai,
    required this.waktuRataRataTes,
    required this.totalMahasiswa,
  });

  factory LaporanOverviewModel.empty() => const LaporanOverviewModel(
        tingkatPenyelesaianTes: 0,
        deltaVsBulanLalu: 0,
        mahasiswaAktif: 0,
        persenMahasiswaAktif: 0,
        roadmapSelesai: 0,
        persenRoadmapSelesai: 0,
        waktuRataRataTes: 0,
        totalMahasiswa: 0,
      );
}

/// Data untuk grafik "Kesiapan per Semester" (bar chart).
/// Setiap item = 1 semester dengan rata-rata % kesiapan akademik mahasiswanya.
class KesiapanPerSemesterModel {
  final String label; // "Sem 1", "Sem 2", dst
  final double persenKesiapan; // 0–100

  const KesiapanPerSemesterModel({
    required this.label,
    required this.persenKesiapan,
  });
}

/// Data untuk grafik "Sebaran Jenjang" (donut chart).
class SebaranJenjangModel {
  final String jenjang; // "S1", "D3", "D4"
  final int jumlah;
  final double persentase;

  const SebaranJenjangModel({
    required this.jenjang,
    required this.jumlah,
    required this.persentase,
  });
}

/// Data untuk tab "Analisis Tes" — sebaran tipe dominan per tes.
class AnalisesTestModel {
  /// RIASEC: berapa mahasiswa per tipe dominan (R/I/A/S/E/C)
  final Map<String, int> sebaranRiasec;

  /// DISC: berapa mahasiswa per tipe dominan (D/I/S/C)
  final Map<String, int> sebaranDisc;

  /// Bakat: berapa mahasiswa per kategori (analitis/kreatif/praktis)
  final Map<String, int> sebaranBakat;

  /// Rata-rata skor per dimensi RIASEC seluruh mahasiswa
  final Map<String, double> rataRataSkorRiasec;

  const AnalisesTestModel({
    required this.sebaranRiasec,
    required this.sebaranDisc,
    required this.sebaranBakat,
    required this.rataRataSkorRiasec,
  });

  factory AnalisesTestModel.empty() => const AnalisesTestModel(
        sebaranRiasec: {},
        sebaranDisc: {},
        sebaranBakat: {},
        rataRataSkorRiasec: {},
      );
}

/// Data untuk tab "Sebaran Karir" — karir apa yang paling banyak
/// direkomendasikan + rata-rata skor kecocokan per karir.
class SebaranKarirModel {
  final String karirId;
  final String namaKarir;
  final String emoji;
  final int jumlahDirekomendasikan;
  final double rataRataSkorAkhir;
  final double rataRataKesiapanAkademik;

  const SebaranKarirModel({
    required this.karirId,
    required this.namaKarir,
    required this.emoji,
    required this.jumlahDirekomendasikan,
    required this.rataRataSkorAkhir,
    required this.rataRataKesiapanAkademik,
  });
}

/// Bungkus semua data laporan — satu objek yang dikembalikan repository
/// ke controller, supaya cukup 1 Future untuk seluruh halaman.
class LaporanData {
  final LaporanOverviewModel overview;
  final List<KesiapanPerSemesterModel> kesiapanPerSemester;
  final List<SebaranJenjangModel> sebaranJenjang;
  final AnalisesTestModel analisisTes;
  final List<SebaranKarirModel> sebaranKarir;
  final DateTime dimuatPada;

  const LaporanData({
    required this.overview,
    required this.kesiapanPerSemester,
    required this.sebaranJenjang,
    required this.analisisTes,
    required this.sebaranKarir,
    required this.dimuatPada,
  });
}

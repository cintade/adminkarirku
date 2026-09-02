import 'package:cloud_firestore/cloud_firestore.dart';
import 'laporan_model.dart';

// ══════════════════════════════════════════════════════════════
// LAPORAN REPOSITORY
//
// Mengambil data dari Firestore yang dibutuhkan halaman Laporan Admin.
//
// Collection yang dibaca:
//   users              — total mahasiswa, jenjang, status aktif
//   hasil_riasec       — sebaran tipe dominan RIASEC
//   hasil_disc         — sebaran tipe dominan DISC
//   hasil_bakat        — sebaran kategori bakat
//   rekomendasi_karir  — sebaran karir yang direkomendasikan
//   data_akademik      — kesiapan akademik per semester
//   roadmap            — jumlah roadmap selesai
// ══════════════════════════════════════════════════════════════
class LaporanRepository {
  final FirebaseFirestore _db;

  LaporanRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Entry point utama — ambil semua data laporan sekaligus (parallel).
  Future<LaporanData> getLaporanData() async {
    // Parallel fetch supaya tidak menunggu satu per satu
    final results = await Future.wait([
      _getUsers(),
      _getHasilRiasec(),
      _getHasilDisc(),
      _getHasilBakat(),
      _getRekomendasiKarir(),
      _getRoadmap(),
      _getDataAkademik(),
    ]);

    final users = results[0] as List<Map<String, dynamic>>;
    final hasilRiasec = results[1] as List<Map<String, dynamic>>;
    final hasilDisc = results[2] as List<Map<String, dynamic>>;
    final hasilBakat = results[3] as List<Map<String, dynamic>>;
    final rekomendasi = results[4] as List<Map<String, dynamic>>;
    final roadmaps = results[5] as List<Map<String, dynamic>>;
    final dataAkademik = results[6] as List<Map<String, dynamic>>;

    return LaporanData(
      overview: _hitungOverview(
        users: users,
        hasilRiasec: hasilRiasec,
        hasilDisc: hasilDisc,
        hasilBakat: hasilBakat,
        roadmaps: roadmaps,
      ),
      kesiapanPerSemester: _hitungKesiapanPerSemester(dataAkademik, users),
      sebaranJenjang: _hitungSebaranJenjang(users),
      analisisTes: _hitungAnaliseTes(hasilRiasec, hasilDisc, hasilBakat),
      sebaranKarir: _hitungSebaranKarir(rekomendasi),
      dimuatPada: DateTime.now(),
    );
  }

  // ── Fetch helpers ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _getHasilRiasec() async {
    final snap = await _db.collection('hasil_riasec').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _getHasilDisc() async {
    final snap = await _db.collection('hasil_disc').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _getHasilBakat() async {
    final snap = await _db.collection('hasil_bakat').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _getRekomendasiKarir() async {
    final snap = await _db.collection('rekomendasi_karir').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _getRoadmap() async {
    final snap = await _db.collection('roadmap').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> _getDataAkademik() async {
    final snap = await _db.collection('data_akademik').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ── Kalkulasi ──────────────────────────────────────────────────────────

  LaporanOverviewModel _hitungOverview({
    required List<Map<String, dynamic>> users,
    required List<Map<String, dynamic>> hasilRiasec,
    required List<Map<String, dynamic>> hasilDisc,
    required List<Map<String, dynamic>> hasilBakat,
    required List<Map<String, dynamic>> roadmaps,
  }) {
    final total = users.length;
    if (total == 0) return LaporanOverviewModel.empty();

    // Mahasiswa yang sudah selesai ketiga tes
    final uidRiasec = hasilRiasec.map((e) => e['id'] as String).toSet();
    final uidDisc = hasilDisc.map((e) => e['id'] as String).toSet();
    final uidBakat = hasilBakat.map((e) => e['id'] as String).toSet();
    final selesaiSemua =
        uidRiasec.intersection(uidDisc).intersection(uidBakat).length;
    final tingkatPenyelesaian = (selesaiSemua / total) * 100;

    // Mahasiswa aktif = punya data hasil tes minimal 1
    final aktivSet = uidRiasec.union(uidDisc).union(uidBakat);
    final mahasiswaAktif = aktivSet.length;

    // Roadmap selesai = status_roadmap == 'selesai'
    final roadmapSelesai = roadmaps
        .where((r) =>
            (r['status_roadmap'] ?? r['status'] ?? '') == 'selesai')
        .length;
    final totalRoadmap = roadmaps.length;
    final persenRoadmap =
        totalRoadmap > 0 ? (roadmapSelesai / totalRoadmap) * 100 : 0.0;

    return LaporanOverviewModel(
      tingkatPenyelesaianTes: double.parse(tingkatPenyelesaian.toStringAsFixed(1)),
      deltaVsBulanLalu: 3.0, // idealnya hitung dari snapshot bulan lalu
      mahasiswaAktif: mahasiswaAktif,
      persenMahasiswaAktif: total > 0
          ? double.parse(((mahasiswaAktif / total) * 100).toStringAsFixed(1))
          : 0,
      roadmapSelesai: roadmapSelesai,
      persenRoadmapSelesai: double.parse(persenRoadmap.toStringAsFixed(1)),
      waktuRataRataTes: 18.0, // opsional: hitung dari durasi_tes jika disimpan
      totalMahasiswa: total,
    );
  }

  List<KesiapanPerSemesterModel> _hitungKesiapanPerSemester(
    List<Map<String, dynamic>> dataAkademik,
    List<Map<String, dynamic>> users,
  ) {
    // Buat map uid → semester dari users
    final semesterPerUid = <String, String>{};
    for (final u in users) {
      final uid = u['id'] as String? ?? '';
      final sem = (u['semester'] ?? u['semester_aktif'] ?? '').toString();
      if (uid.isNotEmpty && sem.isNotEmpty) semesterPerUid[uid] = sem;
    }

    // Kelompokkan kesiapan akademik per semester
    final skorPerSem = <String, List<double>>{};
    for (final d in dataAkademik) {
      final uid = d['id'] as String? ?? '';
      final sem = semesterPerUid[uid];
      if (sem == null) continue;
      final totalMk = (d['total_mk'] as num?)?.toInt() ?? 0;
      if (totalMk == 0) continue;
      // Pendekatan sederhana: rata-rata nilaiNormalisasi dari summary
      // (detail per MK memerlukan subcollection query tambahan)
      final persenKesiapan =
          ((d['persen_kesiapan'] as num?)?.toDouble() ?? 60.0);
      scorkerPerSem(skorPerSem, sem, persenKesiapan);
    }

    // Urutkan per semester 1-8
    final semLabels = List.generate(8, (i) => '${i + 1}');
    return semLabels.map((s) {
      final skors = skorPerSem[s] ?? [];
      final avg = skors.isEmpty
          ? 0.0
          : skors.reduce((a, b) => a + b) / skors.length;
      return KesiapanPerSemesterModel(
        label: 'Sem $s',
        persenKesiapan: double.parse(avg.toStringAsFixed(1)),
      );
    }).toList();
  }

  void scorkerPerSem(
      Map<String, List<double>> map, String sem, double nilai) {
    map.putIfAbsent(sem, () => []).add(nilai);
  }

  List<SebaranJenjangModel> _hitungSebaranJenjang(
      List<Map<String, dynamic>> users) {
    final count = <String, int>{};
    for (final u in users) {
      final j = (u['jenjang'] ?? u['jenjang_pendidikan'] ?? 'S1').toString();
      count[j] = (count[j] ?? 0) + 1;
    }
    final total = users.length;
    return count.entries.map((e) {
      return SebaranJenjangModel(
        jenjang: e.key,
        jumlah: e.value,
        persentase: total > 0
            ? double.parse(((e.value / total) * 100).toStringAsFixed(1))
            : 0,
      );
    }).toList()
      ..sort((a, b) => b.jumlah.compareTo(a.jumlah));
  }

  AnalisesTestModel _hitungAnaliseTes(
    List<Map<String, dynamic>> hasilRiasec,
    List<Map<String, dynamic>> hasilDisc,
    List<Map<String, dynamic>> hasilBakat,
  ) {
    // Sebaran RIASEC
    final sebaranR = <String, int>{};
    final rataR = <String, double>{};
    for (final r in hasilRiasec) {
      final tipe = (r['tipe_dominan'] as String? ?? '').toUpperCase();
      if (tipe.isNotEmpty) sebaranR[tipe] = (sebaranR[tipe] ?? 0) + 1;
      for (final dim in ['R', 'I', 'A', 'S', 'E', 'C']) {
        final skor = (r['skor_$dim'] as num?)?.toDouble() ?? 0;
        rataR[dim] = (rataR[dim] ?? 0) + skor;
      }
    }
    if (hasilRiasec.isNotEmpty) {
      rataR.updateAll((k, v) => v / hasilRiasec.length);
    }

    // Sebaran DISC
    final sebaranD = <String, int>{};
    for (final d in hasilDisc) {
      final tipe = (d['tipe_dominan'] as String? ?? '').toUpperCase();
      if (tipe.isNotEmpty) sebaranD[tipe] = (sebaranD[tipe] ?? 0) + 1;
    }

    // Sebaran Bakat
    final sebaranB = <String, int>{};
    for (final b in hasilBakat) {
      final skor = Map<String, dynamic>.from(
          b['skor_perkategori'] as Map? ?? {});
      if (skor.isEmpty) continue;
      String dominan = 'analitis';
      double max = -1;
      skor.forEach((k, v) {
        final val = (v as num).toDouble();
        if (val > max) {
          max = val;
          dominan = k.toLowerCase();
        }
      });
      sebaranB[dominan] = (sebaranB[dominan] ?? 0) + 1;
    }

    return AnalisesTestModel(
      sebaranRiasec: sebaranR,
      sebaranDisc: sebaranD,
      sebaranBakat: sebaranB,
      rataRataSkorRiasec: rataR,
    );
  }

  List<SebaranKarirModel> _hitungSebaranKarir(
      List<Map<String, dynamic>> rekomendasi) {
    final karirCount = <String, _KarirAggr>{};

    for (final r in rekomendasi) {
      final list = List<Map<String, dynamic>>.from(
          r['rekomendasi'] as List? ?? []);
      for (final item in list) {
        final id = item['karir_id'] as String? ?? '';
        if (id.isEmpty) continue;
        final nama = item['nama_karir'] as String? ?? id;
        final emoji = item['emoji'] as String? ?? '💼';
        final skor = (item['skor_akhir'] as num?)?.toDouble() ?? 0;
        final kesiapan =
            (item['persen_kesiapan_akademik'] as num?)?.toDouble() ?? 0;
        final agg = karirCount.putIfAbsent(
            id, () => _KarirAggr(nama: nama, emoji: emoji));
        agg.jumlah++;
        agg.totalSkor += skor;
        agg.totalKesiapan += kesiapan;
      }
    }

    return karirCount.entries.map((e) {
      final agg = e.value;
      return SebaranKarirModel(
        karirId: e.key,
        namaKarir: agg.nama,
        emoji: agg.emoji,
        jumlahDirekomendasikan: agg.jumlah,
        rataRataSkorAkhir: agg.jumlah > 0
            ? double.parse((agg.totalSkor / agg.jumlah).toStringAsFixed(1))
            : 0,
        rataRataKesiapanAkademik: agg.jumlah > 0
            ? double.parse(
                (agg.totalKesiapan / agg.jumlah).toStringAsFixed(1))
            : 0,
      );
    }).toList()
      ..sort((a, b) =>
          b.jumlahDirekomendasikan.compareTo(a.jumlahDirekomendasikan));
  }
}

class _KarirAggr {
  final String nama;
  final String emoji;
  int jumlah = 0;
  double totalSkor = 0;
  double totalKesiapan = 0;
  _KarirAggr({required this.nama, required this.emoji});
}

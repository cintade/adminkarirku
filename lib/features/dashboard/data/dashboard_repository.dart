import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Model: Statistik Bulanan ────────────────────────────────────────────────
class StatBulanan {
  final String bulan;
  final int pendaftar;
  final int tesSelesai;

  const StatBulanan({
    required this.bulan,
    required this.pendaftar,
    required this.tesSelesai,
  });
}

// ─── Model: Karir Terpopuler ─────────────────────────────────────────────────
class KarirPopuler {
  final String namaKarir;
  final int jumlahMahasiswa;

  const KarirPopuler({required this.namaKarir, required this.jumlahMahasiswa});
}

// ─── Model: Aktivitas Terbaru ─────────────────────────────────────────────────
class AktivitasTerbaru {
  final String deskripsi;
  final DateTime waktu;
  final String tipe; // 'tes', 'roadmap', 'daftar', 'admin'

  const AktivitasTerbaru({
    required this.deskripsi,
    required this.waktu,
    required this.tipe,
  });
}

// ─── Model: Summary Dashboard ─────────────────────────────────────────────────
class DashboardSummary {
  final int totalMahasiswa;
  final int tesSelesai;
  final int roadmapAktif;
  final double rataKesiapan;
  final Map<String, int> distribusiRiasec;
  final List<KarirPopuler> karirPopuler;
  final List<AktivitasTerbaru> aktivitasTerbaru;
  final List<StatBulanan> statBulanan;

  const DashboardSummary({
    required this.totalMahasiswa,
    required this.tesSelesai,
    required this.roadmapAktif,
    required this.rataKesiapan,
    required this.distribusiRiasec,
    required this.karirPopuler,
    required this.aktivitasTerbaru,
    required this.statBulanan,
  });
}

// ─── Repository ──────────────────────────────────────────────────────────────
//
// CATATAN PENTING (setelah dicek langsung ke Firebase Console):
// - Collection `users` TIDAK punya field `role`. Semua dokumen di situ
//   diasumsikan mahasiswa, jadi tidak ada filter `where('role', ...)` lagi.
// - Field tanggal pendaftaran namanya `createdAt` (camelCase), bukan
//   `created_at`.
// - Status tes TIDAK disimpan di `users`. Dicek dari keberadaan dokumen
//   di hasil_riasec/{uid}, hasil_disc/{uid}, hasil_bakat/{uid}.
// - RIASEC dominan diambil dari field `tipe_dominan` di hasil_riasec/{uid}
//   (formatnya dua huruf, mis. "IC" — untuk donut chart kita pakai huruf
//   pertamanya saja sebagai tipe utama).
// - Karir & kesiapan diambil dari rekomendasi_karir/{uid}, field
//   `rekomendasi` (array of map) dengan `nama_karir`, `skor_akhir`, dan
//   `persen_kesiapan_akademik`. Karena urutan array belum tentu terurut,
//   kita ambil elemen dengan `skor_akhir` tertinggi sebagai rekomendasi utama.
// - Roadmap aktif dihitung dari jumlah mahasiswa_id UNIK di collection
//   `roadmap` (bukan field boolean di `users`).
//
// Semua query di sini SENGAJA dibuat tanpa kombinasi where+orderBy atau
// where ganda pada field berbeda, supaya tidak perlu composite index —
// konsisten dengan pola yang sudah dipakai di modul lain KarirKu.
// Konsekuensinya: filtering/agregasi dilakukan di client (Dart), bukan di
// Firestore. Untuk skala ratusan mahasiswa ini masih wajar; kalau nanti
// jumlah mahasiswa sudah ribuan, bagian ini perlu dioptimasi lagi (misal
// dengan field ringkasan yang di-precompute, atau Cloud Function).
class DashboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ambil semua data dashboard secara real-time.
  /// Trigger utama: perubahan di collection `users`. Kalau ada perubahan
  /// besar di collection lain (hasil tes, roadmap, dst) tanpa perubahan
  /// di `users`, dashboard butuh refresh manual (pull-to-refresh / reload
  /// halaman) untuk versi sederhana ini.
  Stream<DashboardSummary> streamDashboard() {
    return _db
        .collection('users')
        .snapshots()
        .asyncMap((usersSnap) => _fetchAll(usersSnap.docs));
  }

  Future<DashboardSummary> _fetchAll(
      List<QueryDocumentSnapshot> userDocs) async {
    final results = await Future.wait([
      _hitungStatusTesDanRiasec(
          userDocs), // gabung: tesSelesai + distribusiRiasec
      _hitungRoadmapAktif(),
      _hitungKarirDanKesiapan(userDocs), // gabung: karirPopuler + rataKesiapan
      _aktivitasTerbaru(),
      _statBulanan(userDocs),
    ]);

    final statusTesInfo = results[0] as _StatusTesInfo;
    final roadmapAktif = results[1] as int;
    final karirInfo = results[2] as _KarirInfo;
    final aktivitas = results[3] as List<AktivitasTerbaru>;
    final statBulanan = results[4] as List<StatBulanan>;

    return DashboardSummary(
      totalMahasiswa: userDocs.length,
      tesSelesai: statusTesInfo.jumlahLengkap,
      roadmapAktif: roadmapAktif,
      rataKesiapan: karirInfo.rataKesiapan,
      distribusiRiasec: statusTesInfo.distribusi,
      karirPopuler: karirInfo.karirPopuler,
      aktivitasTerbaru: aktivitas,
      statBulanan: statBulanan,
    );
  }

  // ── Status tes (Lengkap/Sebagian/Belum) + distribusi RIASEC ──────────────
  // Digabung jadi 1 fungsi karena sama-sama butuh baca hasil_riasec/{uid}
  // per mahasiswa — daripada baca 2x, sekalian dipakai bareng.
  Future<_StatusTesInfo> _hitungStatusTesDanRiasec(
      List<QueryDocumentSnapshot> userDocs) async {
    int lengkap = 0;
    final Map<String, int> distribusi = {
      'R': 0,
      'I': 0,
      'A': 0,
      'S': 0,
      'E': 0,
      'C': 0,
    };

    // Baca hasil tes semua mahasiswa secara paralel.
    final semuaHasil = await Future.wait(userDocs.map((u) async {
      final uid = u.id;
      final hasil = await Future.wait([
        _db.collection('hasil_riasec').doc(uid).get(),
        _db.collection('hasil_disc').doc(uid).get(),
        _db.collection('hasil_bakat').doc(uid).get(),
      ]);
      return hasil;
    }));

    for (final hasil in semuaHasil) {
      final docRiasec = hasil[0];
      final selesaiCount = hasil.where((d) => d.exists).length;
      if (selesaiCount == 3) lengkap++;

      if (docRiasec.exists) {
        final data = docRiasec.data() as Map<String, dynamic>?;
        final tipeDominan = data?['tipe_dominan'] as String?;
        if (tipeDominan != null && tipeDominan.isNotEmpty) {
          final hurufPertama = tipeDominan.substring(0, 1).toUpperCase();
          if (distribusi.containsKey(hurufPertama)) {
            distribusi[hurufPertama] = distribusi[hurufPertama]! + 1;
          }
        }
      }
    }

    return _StatusTesInfo(jumlahLengkap: lengkap, distribusi: distribusi);
  }

  // ── Roadmap aktif: jumlah mahasiswa_id UNIK di collection `roadmap` ───────
  Future<int> _hitungRoadmapAktif() async {
    // Query tanpa where/orderBy sama sekali -> tidak butuh index apapun.
    final snap = await _db.collection('roadmap').get();
    final idUnik = <String>{};
    for (final doc in snap.docs) {
      final mahasiswaId = doc.data()['mahasiswa_id'] as String?;
      if (mahasiswaId != null && mahasiswaId.isNotEmpty) {
        idUnik.add(mahasiswaId);
      }
    }
    return idUnik.length;
  }

  // ── Karir terpopuler + rata-rata kesiapan, dari rekomendasi_karir/{uid} ──
  Future<_KarirInfo> _hitungKarirDanKesiapan(
      List<QueryDocumentSnapshot> userDocs) async {
    final Map<String, int> hitungKarir = {};
    double totalKesiapan = 0;
    int jumlahAdaRekomendasi = 0;

    final semuaDoc = await Future.wait(userDocs.map(
      (u) => _db.collection('rekomendasi_karir').doc(u.id).get(),
    ));

    for (final doc in semuaDoc) {
      if (!doc.exists) continue;
      final data = doc.data() as Map<String, dynamic>?;
      final list = data?['rekomendasi'] as List<dynamic>?;
      if (list == null || list.isEmpty) continue;

      // Ambil elemen dengan skor_akhir tertinggi sebagai rekomendasi utama
      // (array belum tentu terurut, jadi jangan asumsikan index 0 = terbaik).
      Map<String, dynamic>? terbaik;
      double skorTerbaik = -1;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final skor = (map['skor_akhir'] as num?)?.toDouble() ?? 0;
        if (skor > skorTerbaik) {
          skorTerbaik = skor;
          terbaik = map;
        }
      }

      if (terbaik != null) {
        final nama = terbaik['nama_karir'] as String?;
        if (nama != null && nama.isNotEmpty) {
          hitungKarir[nama] = (hitungKarir[nama] ?? 0) + 1;
        }
        final kesiapan =
            (terbaik['persen_kesiapan_akademik'] as num?)?.toDouble() ?? 0;
        totalKesiapan += kesiapan;
        jumlahAdaRekomendasi++;
      }
    }

    final sorted = hitungKarir.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final karirPopuler = sorted
        .take(5)
        .map((e) => KarirPopuler(namaKarir: e.key, jumlahMahasiswa: e.value))
        .toList();

    final rataKesiapan =
        jumlahAdaRekomendasi == 0 ? 0.0 : totalKesiapan / jumlahAdaRekomendasi;

    return _KarirInfo(karirPopuler: karirPopuler, rataKesiapan: rataKesiapan);
  }

  // ── Aktivitas terbaru dari koleksi aktivitas ──────────────────────────────
  // orderBy 1 field saja -> tidak butuh composite index.
  Future<List<AktivitasTerbaru>> _aktivitasTerbaru() async {
    try {
      final snap = await _db
          .collection('aktivitas')
          .orderBy('waktu', descending: true)
          .limit(6)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data();
        return AktivitasTerbaru(
          deskripsi: d['deskripsi'] ?? '',
          waktu: (d['waktu'] as Timestamp?)?.toDate() ?? DateTime.now(),
          tipe: d['tipe'] ?? 'info',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Statistik bulanan, dihitung client-side dari createdAt user ──────────
  // Sengaja TIDAK query collection terpisah dengan double orderBy (itu yang
  // butuh composite index sebelumnya). Karena kita sudah punya userDocs di
  // tangan, tinggal dikelompokkan per bulan di Dart.
  Future<List<StatBulanan>> _statBulanan(
      List<QueryDocumentSnapshot> userDocs) async {
    final now = DateTime.now();
    const namaBulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    // Siapkan 6 bucket bulan (bulan ini + 5 bulan ke belakang)
    final bucket = <DateTime, int>{};
    for (int i = 5; i >= 0; i--) {
      final bulan = DateTime(now.year, now.month - i, 1);
      bucket[bulan] = 0;
    }

    for (final doc in userDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      DateTime? tanggal;
      if (ts is Timestamp) {
        tanggal = ts.toDate();
      } else if (ts is String) {
        tanggal = DateTime.tryParse(ts);
      }
      if (tanggal == null) continue;

      final bulanKey = DateTime(tanggal.year, tanggal.month, 1);
      if (bucket.containsKey(bulanKey)) {
        bucket[bulanKey] = bucket[bulanKey]! + 1;
      }
    }

    // TODO: tesSelesai per bulan belum dihitung (butuh field tanggal_tes
    // per hasil, dikelompokkan sama seperti pendaftar). Untuk sekarang
    // ditampilkan 0 dulu supaya grafik tetap render tanpa query tambahan.
    return bucket.entries
        .map((e) => StatBulanan(
              bulan: namaBulan[e.key.month],
              pendaftar: e.value,
              tesSelesai: 0,
            ))
        .toList();
  }
}

class _StatusTesInfo {
  final int jumlahLengkap;
  final Map<String, int> distribusi;
  _StatusTesInfo({required this.jumlahLengkap, required this.distribusi});
}

class _KarirInfo {
  final List<KarirPopuler> karirPopuler;
  final double rataKesiapan;
  _KarirInfo({required this.karirPopuler, required this.rataKesiapan});
}

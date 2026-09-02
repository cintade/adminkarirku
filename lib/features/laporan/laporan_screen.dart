import 'package:flutter/material.dart';
import 'data/laporan_model.dart';
import 'data/laporan_repository.dart';
import 'data/laporan_export_service.dart';
import 'widgets/laporan_widgets.dart';

// ══════════════════════════════════════════════════════════════
// LAPORAN SCREEN
//
// Halaman "Laporan & Analitik" untuk admin dashboard.
// Terdiri dari 3 tab:
//   1. Overview   — 4 stat card + bar chart + donut chart
//   2. Analisis Tes — sebaran tipe dominan RIASEC/DISC/Bakat
//   3. Sebaran Karir — tabel karir yang paling direkomendasikan
//
// Cara pasang di router admin (sesuaikan dengan routing yang sudah ada):
//
//   // Di halaman shell/layout admin, tambahkan ke daftar halaman:
//   case 'laporan':
//     return const LaporanScreen();
// ══════════════════════════════════════════════════════════════

const _colorPrimary = Color(0xFF1E3A5F);
const _colorAccent = Color(0xFF2563EB);
const _colorSuccess = Color(0xFF16A34A);
const _colorWarning = Color(0xFFF59E0B);
const _colorSurface = Color(0xFFFFFFFF);
const _colorBg = Color(0xFFF1F5F9);
const _colorBorder = Color(0xFFE2E8F0);
const _colorText = Color(0xFF1E293B);
const _colorTextSub = Color(0xFF64748B);

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen>
    with SingleTickerProviderStateMixin {
  final LaporanRepository _repo = LaporanRepository();
  late final TabController _tabCtrl;
  late Future<LaporanData> _future;
  bool _isExportingExcel = false;
  bool _isExportingPdf = false;

  Future<void> _eksporExcel(BuildContext context, LaporanData data) async {
    setState(() => _isExportingExcel = true);
    await LaporanExportService.eksporExcel(context, data);
    if (mounted) setState(() => _isExportingExcel = false);
  }

  Future<void> _eksporPdf(BuildContext context, LaporanData data) async {
    setState(() => _isExportingPdf = true);
    await LaporanExportService.eksporPdf(context, data);
    if (mounted) setState(() => _isExportingPdf = false);
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _future = _repo.getLaporanData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _future = _repo.getLaporanData());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorBg,
      body: FutureBuilder<LaporanData>(
        future: _future,
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final hasError = snap.hasError;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(isLoading, snap.data),
              if (hasError) _buildError(snap.error.toString()),
              if (!hasError)
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(snap.data!),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Top bar: judul + tab + tombol ekspor ──────────────────────────────
  Widget _buildTopBar(bool isLoading, LaporanData? data) {
    return Container(
      color: _colorSurface,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Laporan & Analitik',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _colorText)),
                    SizedBox(height: 2),
                    Text(
                        'Data diambil langsung dari Firestore — '
                        'tarik ke bawah atau klik Muat Ulang untuk refresh.',
                        style: TextStyle(fontSize: 12, color: _colorTextSub)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tombol muat ulang
              OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Muat Ulang'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _colorTextSub,
                  side: const BorderSide(color: _colorBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              // PDF: langsung unduh file .pdf tanpa dialog
              if (data != null)
                ElevatedButton.icon(
                  onPressed:
                      _isExportingPdf ? null : () => _eksporPdf(context, data),
                  icon: _isExportingPdf
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: Text(_isExportingPdf ? 'Menyiapkan...' : 'Ekspor PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _colorPrimary.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                    elevation: 0,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Ekspor PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                    elevation: 0,
                  ),
                ),
              const SizedBox(width: 8),
              // Excel: langsung unduh file .xlsx tanpa dialog
              if (data != null)
                ElevatedButton.icon(
                  onPressed: _isExportingExcel
                      ? null
                      : () => _eksporExcel(context, data),
                  icon: _isExportingExcel
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.table_chart_outlined, size: 16),
                  label: Text(
                      _isExportingExcel ? 'Menyiapkan...' : 'Ekspor Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorSuccess,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _colorSuccess.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                    elevation: 0,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.table_chart_outlined, size: 16),
                  label: const Text('Ekspor Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colorSuccess,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabCtrl,
            isScrollable: false,
            labelColor: _colorAccent,
            unselectedLabelColor: _colorTextSub,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            indicatorColor: _colorAccent,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Analisis Tes'),
              Tab(text: 'Sebaran Karir'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Konten utama (3 tab) ──────────────────────────────────────────────
  Widget _buildContent(LaporanData data) {
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _TabOverview(data: data),
        _TabAnalisaTes(data: data),
        _TabSebaranKarir(data: data),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _colorTextSub)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — OVERVIEW
// ══════════════════════════════════════════════════════════════
class _TabOverview extends StatelessWidget {
  final LaporanData data;
  const _TabOverview({required this.data});

  @override
  Widget build(BuildContext context) {
    final ov = data.overview;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 stat card
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 900
                ? 4
                : c.maxWidth > 600
                    ? 2
                    : 1;
            return _ResponsiveGrid(
              columns: cols,
              children: [
                StatKartuWidget(
                  judul: 'Tingkat Penyelesaian Tes',
                  nilai: '${ov.tingkatPenyelesaianTes.toStringAsFixed(0)}%',
                  sublabel: '+${ov.deltaVsBulanLalu}% vs bulan lalu',
                  icon: Icons.assignment_turned_in_outlined,
                  warna: _colorAccent,
                ),
                StatKartuWidget(
                  judul: 'Mahasiswa Aktif',
                  nilai: '${ov.mahasiswaAktif}',
                  sublabel:
                      '${ov.persenMahasiswaAktif.toStringAsFixed(0)}% dari total',
                  icon: Icons.people_outline,
                  warna: _colorSuccess,
                ),
                StatKartuWidget(
                  judul: 'Roadmap Selesai',
                  nilai: '${ov.roadmapSelesai}',
                  sublabel:
                      '${ov.persenRoadmapSelesai.toStringAsFixed(0)}% dari total',
                  icon: Icons.route_outlined,
                  warna: _colorWarning,
                ),
                StatKartuWidget(
                  judul: 'Waktu Rata-rata Tes',
                  nilai: '${ov.waktuRataRataTes.toStringAsFixed(0)}m',
                  sublabel: 'per sesi',
                  icon: Icons.timer_outlined,
                  warna: const Color(0xFF7C3AED),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          // Bar chart + Donut chart berdampingan
          LayoutBuilder(builder: (context, c) {
            if (c.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child:
                        KesiapanBarChartWidget(data: data.kesiapanPerSemester),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SebaranJenjangDonutWidget(data: data.sebaranJenjang),
                  ),
                ],
              );
            }
            return Column(
              children: [
                KesiapanBarChartWidget(data: data.kesiapanPerSemester),
                const SizedBox(height: 16),
                SebaranJenjangDonutWidget(data: data.sebaranJenjang),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 — ANALISIS TES
// ══════════════════════════════════════════════════════════════
class _TabAnalisaTes extends StatelessWidget {
  final LaporanData data;
  const _TabAnalisaTes({required this.data});

  @override
  Widget build(BuildContext context) {
    final a = data.analisisTes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sebaran Tipe Dominan',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _colorText)),
          const SizedBox(height: 4),
          const Text(
              'Distribusi hasil tes per tipe dominan dari seluruh mahasiswa '
              'yang sudah menyelesaikan tes.',
              style: TextStyle(fontSize: 12, color: _colorTextSub)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 800
                ? 3
                : c.maxWidth > 500
                    ? 2
                    : 1;
            return _ResponsiveGrid(
              columns: cols,
              children: [
                _KartuAnalisis(
                  judul: 'RIASEC',
                  sub: 'Tipe kepribadian Holland',
                  child: SebaranTipeBarWidget(
                    judul: '',
                    data: a.sebaranRiasec,
                    warna: _colorAccent,
                  ),
                ),
                _KartuAnalisis(
                  judul: 'DISC',
                  sub: 'Gaya perilaku dominan',
                  child: SebaranTipeBarWidget(
                    judul: '',
                    data: a.sebaranDisc,
                    warna: _colorSuccess,
                  ),
                ),
                _KartuAnalisis(
                  judul: 'Bakat (Sternberg)',
                  sub: 'Kategori kecerdasan dominan',
                  child: SebaranTipeBarWidget(
                    judul: '',
                    data: a.sebaranBakat,
                    warna: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          // Rata-rata skor RIASEC
          if (a.rataRataSkorRiasec.isNotEmpty)
            _KartuAnalisis(
              judul: 'Rata-rata Skor RIASEC',
              sub:
                  'Nilai rata-rata per dimensi dari seluruh mahasiswa yang sudah tes',
              child: SebaranTipeBarWidget(
                judul: '',
                data:
                    a.rataRataSkorRiasec.map((k, v) => MapEntry(k, v.round())),
                warna: _colorWarning,
              ),
            ),
        ],
      ),
    );
  }
}

class _KartuAnalisis extends StatelessWidget {
  final String judul;
  final String sub;
  final Widget child;

  const _KartuAnalisis(
      {required this.judul, required this.sub, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _colorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _colorText)),
          Text(sub, style: const TextStyle(fontSize: 11, color: _colorTextSub)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 3 — SEBARAN KARIR
// ══════════════════════════════════════════════════════════════
class _TabSebaranKarir extends StatelessWidget {
  final LaporanData data;
  const _TabSebaranKarir({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sebaran Rekomendasi Karir',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _colorText)),
          const SizedBox(height: 4),
          const Text(
              'Karir yang paling sering muncul di rekomendasi, diurutkan '
              'berdasarkan frekuensi rekomendasi.',
              style: TextStyle(fontSize: 12, color: _colorTextSub)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _colorSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _colorBorder),
            ),
            child: SebaranKarirTabelWidget(data: data.sebaranKarir),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HELPER: Responsive grid
// ══════════════════════════════════════════════════════════════
class _ResponsiveGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _ResponsiveGrid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[];
    for (var i = 0; i < children.length; i += columns) {
      rows.add(children.sublist(i, (i + columns).clamp(0, children.length)));
    }
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: row
                .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
                .toList()
              ..removeLast(),
          ),
        );
      }).toList(),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adminkarieku/features/dashboard/data/dashboard_repository.dart';
import 'package:adminkarieku/features/aturan_rekomendasi_karir/presentation/aturan_rekomendasi_list_screen.dart';

// ─── Warna (sesuai app_theme.dart) ───────────────────────────────────────────
class _C {
  static const sidebarBg = Color(0xFF1A2332);
  static const accent = Color(0xFF4FC3F7);
  static const pageBg = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE8ECF0);
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF6B7A8D);
  static const textMuted = Color(0xFF9AA5B4);
  static const primary = Color(0xFF1565C0);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF57F17);
  static const warningLight = Color(0xFFFFFDE7);
  static const dangerLight = Color(0xFFFFEBEE);
  static const danger = Color(0xFFC62828);

  // RIASEC
  static const r = Color(0xFF1565C0);
  static const i = Color(0xFF6A1B9A);
  static const a = Color(0xFFAD1457);
  static const s = Color(0xFF2E7D32);
  static const e = Color(0xFFE65100);
  static const c = Color(0xFF00695C);

  static Color riasec(String t) {
    switch (t.toUpperCase()) {
      case 'R':
        return r;
      case 'I':
        return i;
      case 'A':
        return a;
      case 'S':
        return s;
      case 'E':
        return e;
      case 'C':
        return c;
      default:
        return textMuted;
    }
  }

  static String riasecLabel(String t) {
    switch (t.toUpperCase()) {
      case 'R':
        return 'Realistic';
      case 'I':
        return 'Investigative';
      case 'A':
        return 'Artistic';
      case 'S':
        return 'Social';
      case 'E':
        return 'Enterprising';
      case 'C':
        return 'Conventional';
      default:
        return t;
    }
  }
}

// ─── Dashboard Page ───────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _repo = DashboardRepository();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Bar
        _TopBar(),
        // Content
        Expanded(
          child: StreamBuilder<DashboardSummary>(
            stream: _repo.streamDashboard(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _C.primary),
                );
              }
              if (snapshot.hasError) {
                return _ErrorView(error: snapshot.error.toString());
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('Tidak ada data'));
              }

              final data = snapshot.data!;
              return _DashboardContent(data: data);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: _C.cardBg,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          _AturanRekomendasiButton(),
          const SizedBox(width: 16),
          Container(
            width: 240,
            height: 36,
            decoration: BoxDecoration(
              color: _C.pageBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border),
            ),
            child: const TextField(
              style: TextStyle(fontSize: 13, color: _C.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari mahasiswa, karier...',
                hintStyle: TextStyle(fontSize: 13, color: _C.textMuted),
                prefixIcon: Icon(Icons.search, size: 18, color: _C.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _bulanIni(),
            style: const TextStyle(fontSize: 12, color: _C.textMuted),
          ),
        ],
      ),
    );
  }

  String _bulanIni() {
    final now = DateTime.now();
    const bulan = [
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
      'Des'
    ];
    return '${bulan[now.month]} ${now.year}';
  }
}

// ─── Tombol Aturan Rekomendasi Karir ──────────────────────────────────────────
class _AturanRekomendasiButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AturanRekomendasiListScreen(),
          ),
        );
      },
      icon: const Icon(Icons.rule_folder_outlined, size: 18),
      label: const Text(
        'Aturan Rekomendasi Karir',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ─── Dashboard Content ────────────────────────────────────────────────────────
class _DashboardContent extends StatelessWidget {
  final DashboardSummary data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat Cards ──────────────────────────────────────────────────
          _StatCards(data: data),
          const SizedBox(height: 24),

          // ── Grafik + Distribusi RIASEC ──────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _GrafikBulanan(statBulanan: data.statBulanan),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _DistribusiRiasec(distribusi: data.distribusiRiasec),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Karir Populer + Aktivitas ───────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _KarirPopulerWidget(karirList: data.karirPopuler),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _AktivitasWidget(aktivitas: data.aktivitasTerbaru),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Cards ───────────────────────────────────────────────────────────────
class _StatCards extends StatelessWidget {
  final DashboardSummary data;
  const _StatCards({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Mahasiswa',
            value: data.totalMahasiswa.toString(),
            subtitle: 'terdaftar di aplikasi',
            subtitleColor: _C.success,
            icon: Icons.people_alt_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: _C.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Tes Selesai',
            value: data.tesSelesai.toString(),
            subtitle: 'mahasiswa sudah tes',
            subtitleColor: _C.success,
            icon: Icons.check_circle_outline,
            iconBg: _C.successLight,
            iconColor: _C.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Roadmap Aktif',
            value: data.roadmapAktif.toString(),
            subtitle: 'sedang merencanakan karir',
            subtitleColor: _C.warning,
            icon: Icons.map_outlined,
            iconBg: _C.warningLight,
            iconColor: _C.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Rata-rata Kesiapan',
            value: '${data.rataKesiapan.toStringAsFixed(0)}%',
            subtitle: 'kesiapan karir mahasiswa',
            subtitleColor: _C.primary,
            icon: Icons.trending_up_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: _C.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _C.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                        height: 1.1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 11,
                          color: subtitleColor ?? _C.textMuted,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grafik Bulanan (Custom Painter) ─────────────────────────────────────────
class _GrafikBulanan extends StatelessWidget {
  final List<StatBulanan> statBulanan;
  const _GrafikBulanan({required this.statBulanan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tren Pendaftar & Tes Bulanan',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Lihat semua',
                    style: TextStyle(fontSize: 12, color: _C.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _legendDot(_C.primary, 'Pendaftar'),
              const SizedBox(width: 16),
              _legendDot(_C.success, 'Tes selesai'),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          statBulanan.isEmpty
              ? _emptyChart()
              : SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _LineChartPainter(data: statBulanan),
                    child: const SizedBox.expand(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: _C.textSecondary)),
      ],
    );
  }

  Widget _emptyChart() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: const Text('Belum ada data grafik',
          style: TextStyle(color: _C.textMuted)),
    );
  }
}

// ─── Custom Line Chart Painter ────────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<StatBulanan> data;
  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const padLeft = 40.0;
    const padBottom = 30.0;
    const padTop = 10.0;
    final chartW = size.width - padLeft;
    final chartH = size.height - padBottom - padTop;

    // Hitung max value
    int maxVal = 1;
    for (final d in data) {
      if (d.pendaftar > maxVal) maxVal = d.pendaftar;
      if (d.tesSelesai > maxVal) maxVal = d.tesSelesai;
    }
    maxVal = (maxVal * 1.2).ceil();

    // Grid lines
    final gridPaint = Paint()
      ..color = _C.border
      ..strokeWidth = 1;
    const gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = padTop + chartH - (chartH * i / gridCount);
      canvas.drawLine(Offset(padLeft, y), Offset(size.width, y), gridPaint);
      // Label Y
      final val = (maxVal * i / gridCount).round();
      final tp = TextPainter(
        text: TextSpan(
          text: val.toString(),
          style: const TextStyle(fontSize: 10, color: _C.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // X labels
    final stepX = chartW / (data.length - 1).clamp(1, 100);
    for (int i = 0; i < data.length; i++) {
      final x = padLeft + i * stepX;
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].bulan,
          style: const TextStyle(fontSize: 10, color: _C.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - padBottom + 6));
    }

    _drawLine(canvas, data, maxVal, padLeft, padTop, chartW, chartH, stepX,
        (d) => d.pendaftar.toDouble(), _C.primary);
    _drawLine(canvas, data, maxVal, padLeft, padTop, chartW, chartH, stepX,
        (d) => d.tesSelesai.toDouble(), _C.success);
  }

  void _drawLine(
    Canvas canvas,
    List<StatBulanan> data,
    int maxVal,
    double padLeft,
    double padTop,
    double chartW,
    double chartH,
    double stepX,
    double Function(StatBulanan) getValue,
    Color color,
  ) {
    if (data.length < 2) return;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padLeft + i * stepX;
      final val = getValue(data[i]);
      final y = padTop + chartH - (chartH * val / maxVal);
      points.add(Offset(x, y));
    }

    // Area fill
    final fillPath = Path()..moveTo(points.first.dx, padTop + chartH);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, padTop + chartH);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withOpacity(0.08)
        ..style = PaintingStyle.fill,
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Smooth curve
      final cp1 =
          Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = color);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.data != data;
}

// ─── Distribusi RIASEC (Donut Chart) ─────────────────────────────────────────
class _DistribusiRiasec extends StatelessWidget {
  final Map<String, int> distribusi;
  const _DistribusiRiasec({required this.distribusi});

  @override
  Widget build(BuildContext context) {
    final total = distribusi.values.fold(0, (sum, v) => sum + v);

    // Sort by nilai
    final sorted = distribusi.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi RIASEC',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary),
          ),
          const SizedBox(height: 20),
          // Donut chart
          total == 0
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Belum ada data tes',
                        style: TextStyle(color: _C.textMuted)),
                  ),
                )
              : Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _DonutPainter(data: distribusi),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          // Legend
          ...sorted.map((e) => _legendRow(
                e.key,
                e.value,
                total,
              )),
        ],
      ),
    );
  }

  Widget _legendRow(String tipe, int nilai, int total) {
    final persen = total == 0 ? 0.0 : nilai / total * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _C.riasec(tipe),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _C.riasecLabel(tipe),
              style: const TextStyle(fontSize: 12, color: _C.textSecondary),
            ),
          ),
          Text(
            '${persen.toStringAsFixed(0)}%',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> data;
  _DonutPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (s, v) => s + v);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeW = 28.0;

    double startAngle = -math.pi / 2;
    for (final entry in data.entries) {
      final sweep = 2 * math.pi * entry.value / total;
      canvas.drawArc(
        rect.deflate(strokeW / 2),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = _C.riasec(entry.key)
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.data != data;
}

// ─── Karir Terpopuler ─────────────────────────────────────────────────────────
class _KarirPopulerWidget extends StatelessWidget {
  final List<KarirPopuler> karirList;
  const _KarirPopulerWidget({required this.karirList});

  @override
  Widget build(BuildContext context) {
    final maxVal = karirList.isEmpty
        ? 1
        : karirList.map((k) => k.jumlahMahasiswa).reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Karir Terpopuler',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Detail',
                    style: TextStyle(fontSize: 12, color: _C.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          karirList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Belum ada data rekomendasi',
                        style: TextStyle(color: _C.textMuted)),
                  ),
                )
              : Column(
                  children: karirList.asMap().entries.map((e) {
                    final idx = e.key;
                    final karir = e.value;
                    final persen = karir.jumlahMahasiswa / maxVal;
                    final colors = [
                      _C.primary,
                      _C.i,
                      _C.s,
                      _C.e,
                      _C.c,
                    ];
                    return _KarirRow(
                      nama: karir.namaKarir,
                      jumlah: karir.jumlahMahasiswa,
                      persen: persen,
                      color: colors[idx % colors.length],
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class _KarirRow extends StatelessWidget {
  final String nama;
  final int jumlah;
  final double persen;
  final Color color;

  const _KarirRow({
    required this.nama,
    required this.jumlah,
    required this.persen,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(nama,
                    style: const TextStyle(
                        fontSize: 13,
                        color: _C.textPrimary,
                        fontWeight: FontWeight.w500)),
              ),
              Text('$jumlah mahasiswa',
                  style:
                      const TextStyle(fontSize: 12, color: _C.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: persen,
              minHeight: 6,
              backgroundColor: _C.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aktivitas Terbaru ────────────────────────────────────────────────────────
class _AktivitasWidget extends StatelessWidget {
  final List<AktivitasTerbaru> aktivitas;
  const _AktivitasWidget({required this.aktivitas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Terbaru',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary),
          ),
          const SizedBox(height: 16),
          aktivitas.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Belum ada aktivitas',
                        style: TextStyle(color: _C.textMuted)),
                  ),
                )
              : Column(
                  children: aktivitas
                      .map((a) => _AktivitasRow(aktivitas: a))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _AktivitasRow extends StatelessWidget {
  final AktivitasTerbaru aktivitas;
  const _AktivitasRow({required this.aktivitas});

  Color get _dotColor {
    switch (aktivitas.tipe) {
      case 'tes':
        return _C.success;
      case 'roadmap':
        return _C.warning;
      case 'daftar':
        return _C.primary;
      case 'admin':
        return _C.danger;
      default:
        return _C.textMuted;
    }
  }

  String get _waktuLabel {
    final diff = DateTime.now().difference(aktivitas.waktu);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aktivitas.deskripsi,
                    style:
                        const TextStyle(fontSize: 13, color: _C.textPrimary)),
                const SizedBox(height: 2),
                Text(_waktuLabel,
                    style: const TextStyle(fontSize: 11, color: _C.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: _C.danger, size: 48),
          const SizedBox(height: 12),
          Text('Gagal memuat dashboard',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _C.textPrimary)),
          const SizedBox(height: 4),
          Text(error,
              style: const TextStyle(fontSize: 12, color: _C.textMuted)),
        ],
      ),
    );
  }
}

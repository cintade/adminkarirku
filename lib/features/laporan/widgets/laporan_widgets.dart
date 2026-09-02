import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../data/laporan_model.dart';

// ══════════════════════════════════════════════════════════════
// DESIGN TOKENS — konsisten dengan admin dashboard yang ada
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

// ─────────────────────────────────────────────────────────────
// 1. KARTU STATISTIK UTAMA
// ─────────────────────────────────────────────────────────────
class StatKartuWidget extends StatelessWidget {
  final String judul;
  final String nilai;
  final String? sublabel;
  final IconData icon;
  final Color warna;

  const StatKartuWidget({
    super.key,
    required this.judul,
    required this.nilai,
    this.sublabel,
    required this.icon,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _colorTextSub,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: warna),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nilai,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: warna,
              height: 1,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(
              sublabel!,
              style: const TextStyle(fontSize: 11, color: _colorTextSub),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. BAR CHART — Kesiapan per Semester
// ─────────────────────────────────────────────────────────────
class KesiapanBarChartWidget extends StatelessWidget {
  final List<KesiapanPerSemesterModel> data;

  const KesiapanBarChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        data.isEmpty ? 100.0 : data.map((e) => e.persenKesiapan).reduce(math.max);
    final maxDisplay = maxVal < 10 ? 100.0 : (maxVal * 1.2).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kesiapan per Semester',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _colorText),
          ),
          const Text(
            'Rata-rata % kesiapan akademik mahasiswa per semester aktif',
            style: TextStyle(fontSize: 11, color: _colorTextSub),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: data.isEmpty
                ? const Center(child: Text('Belum ada data'))
                : LayoutBuilder(builder: (context, constraints) {
                    final barW =
                        (constraints.maxWidth / data.length) - 8;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: data.map((item) {
                        final ratio =
                            (item.persenKesiapan / maxDisplay).clamp(0.0, 1.0);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.persenKesiapan.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: _colorAccent),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  width: barW,
                                  height: math.max(4, 140 * ratio),
                                  decoration: BoxDecoration(
                                    color: _colorAccent,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                      fontSize: 9, color: _colorTextSub),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. DONUT CHART — Sebaran Jenjang
// ─────────────────────────────────────────────────────────────
class SebaranJenjangDonutWidget extends StatelessWidget {
  final List<SebaranJenjangModel> data;

  const SebaranJenjangDonutWidget({super.key, required this.data});

  static const _colors = [_colorAccent, _colorSuccess, _colorWarning,
    Color(0xFF7C3AED), Color(0xFFEC4899)];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sebaran Jenjang',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _colorText),
          ),
          const Text(
            'Distribusi mahasiswa berdasarkan jenjang pendidikan',
            style: TextStyle(fontSize: 11, color: _colorTextSub),
          ),
          const SizedBox(height: 24),
          if (data.isEmpty)
            const Center(child: Text('Belum ada data'))
          else
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: _DonutPainter(data: data, colors: _colors),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(data.length, (i) {
                      final item = data[i];
                      final color = _colors[i % _colors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item.jenjang} — ${item.jumlah} mahasiswa',
                                style: const TextStyle(
                                    fontSize: 12, color: _colorText),
                              ),
                            ),
                            Text(
                              '${item.persentase}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<SebaranJenjangModel> data;
  final List<Color> colors;

  _DonutPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 28.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = (data[i].persentase / 100) * 2 * math.pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.data != data;
}

// ─────────────────────────────────────────────────────────────
// 4. HORIZONTAL BAR — Analisis Tes (sebaran per tipe)
// ─────────────────────────────────────────────────────────────
class SebaranTipeBarWidget extends StatelessWidget {
  final String judul;
  final Map<String, int> data;
  final Color warna;

  const SebaranTipeBarWidget({
    super.key,
    required this.judul,
    required this.data,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(judul,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _colorTextSub)),
        const SizedBox(height: 10),
        ...sorted.map((e) {
          final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 36,
                    child: Text(e.key,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _colorText))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 14,
                      backgroundColor: warna.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(warna),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text('${e.value}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, color: _colorTextSub)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 5. TABEL SEBARAN KARIR
// ─────────────────────────────────────────────────────────────
class SebaranKarirTabelWidget extends StatelessWidget {
  final List<SebaranKarirModel> data;

  const SebaranKarirTabelWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Belum ada data rekomendasi karir',
              style: TextStyle(color: _colorTextSub)),
        ),
      );
    }

    return Column(
      children: [
        // Header tabel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _colorBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 32, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _colorTextSub))),
              Expanded(flex: 3, child: Text('Karir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _colorTextSub))),
              Expanded(child: Text('Direkomendasikan', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _colorTextSub))),
              Expanded(child: Text('Rata-rata Skor', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _colorTextSub))),
              Expanded(child: Text('Kesiapan Akademik', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _colorTextSub))),
            ],
          ),
        ),
        ...data.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: i.isEven ? _colorSurface : _colorBg.withOpacity(0.5),
              border: const Border(
                  bottom: BorderSide(color: _colorBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _colorTextSub)),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Text(item.emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(item.namaKarir,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _colorText)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: _colorAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('${item.jumlahDirekomendasikan}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _colorAccent)),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${item.rataRataSkorAkhir}%',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _colorText),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _ProgressPill(
                        value: item.rataRataKesiapanAkademik / 100),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final double value;
  const _ProgressPill({required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toStringAsFixed(0);
    final color = value >= 0.7
        ? _colorSuccess
        : value >= 0.4
            ? _colorWarning
            : Colors.redAccent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$pct%',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

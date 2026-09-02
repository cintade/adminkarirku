import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_sternberg_model.dart';
import 'package:adminkarieku/features/manajemen_tes/data/repositories/soal_sterberg_repository.dart';
import 'tambah_soal_sternberg_dialog.dart';

class TabSternberg extends StatefulWidget {
  const TabSternberg({super.key});

  @override
  State<TabSternberg> createState() => _TabSternbergState();
}

class _TabSternbergState extends State<TabSternberg> {
  final _repo = SoalSternbergRepository();

  /// Part yang sedang dipilih (null = tampilkan semua)
  int? _selectedPart;

  // Warna per dimensi
  static const _dimensiColor = {
    DimensiSternberg.analitis: Color(0xFF2563EB),
    DimensiSternberg.kreatif: Color(0xFFD97706),
    DimensiSternberg.praktis: Color(0xFF16A34A),
  };

  // Warna per format
  static const _formatColor = {
    FormatKonten.verbal: Color(0xFF7C3AED),
    FormatKonten.kuantitatif: Color(0xFF0891B2),
    FormatKonten.figural: Color(0xFFDB2777),
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, int>>(
      future: _repo.countPerPart(),
      builder: (context, snapCount) {
        final countMap = snapCount.data ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildPartSelector(countMap),
            const Divider(height: 1),
            Expanded(child: _buildSoalContent()),
          ],
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Soal Sternberg — STAT',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '9 Part · 3 Dimensi (Analitis, Kreatif, Praktis) × 3 Format (Verbal, Kuantitatif, Figural)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showTambahDialog(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(_selectedPart != null
                ? 'Tambah Soal Part $_selectedPart'
                : 'Tambah Soal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarAccent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Part Selector ─────────────────────────────────────────────────────────
  Widget _buildPartSelector(Map<int, int> countMap) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legenda dimensi + format
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ..._dimensiColor.entries.map((e) => _legendChip(
                    e.key.label,
                    e.value,
                    Icons.psychology_outlined,
                  )),
              ..._formatColor.entries.map((e) => _legendChip(
                    e.key.label,
                    e.value,
                    Icons.category_outlined,
                    isFormat: true,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          // Tombol "Semua" + Part 1–9
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Tombol semua
                _partButton(
                  label: 'Semua',
                  count: countMap.values.fold(0, (a, b) => a + b),
                  isActive: _selectedPart == null,
                  color: Colors.grey.shade600,
                  onTap: () => setState(() => _selectedPart = null),
                ),
                const SizedBox(width: 8),
                // Part 1–9
                ...StatPart.semuaPart.map((part) {
                  final count = countMap[part.noPart] ?? 0;
                  final color =
                      _dimensiColor[part.dimensi] ?? Colors.grey;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _partButton(
                      label: 'Part ${part.noPart}',
                      subtitle:
                          '${part.dimensi.label}\n${part.format.label}',
                      count: count,
                      isActive: _selectedPart == part.noPart,
                      color: color,
                      onTap: () =>
                          setState(() => _selectedPart = part.noPart),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(String label, Color color, IconData icon,
      {bool isFormat = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: color.withOpacity(0.25),
              style: isFormat ? BorderStyle.solid : BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _partButton({
    required String label,
    String? subtitle,
    required int count,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? color : Colors.grey.shade700)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? color.withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: count > 0
                            ? color
                            : Colors.grey.shade400),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 9,
                      color: isActive
                          ? color.withOpacity(0.8)
                          : Colors.grey.shade500,
                      height: 1.3)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Soal Content ──────────────────────────────────────────────────────────
  Widget _buildSoalContent() {
    final stream = _selectedPart != null
        ? _repo.streamSoalByPart(_selectedPart!)
        : _repo.streamSoal();

    return StreamBuilder<List<SoalSternberg>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        if (list.isEmpty) return _buildEmptyState();
        return _buildTable(context, list);
      },
    );
  }

  Widget _buildTable(BuildContext context, List<SoalSternberg> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Table(
        border: TableBorder(
          horizontalInside:
              BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        columnWidths: const {
          0: FixedColumnWidth(60),   // Part·No
          1: FixedColumnWidth(130),  // Dimensi + Format
          2: FlexColumnWidth(2.5),   // Konteks
          3: FlexColumnWidth(3),     // Pernyataan
          4: FlexColumnWidth(4),     // Pilihan
          5: FixedColumnWidth(72),   // Aksi
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: [
              _th('Part·No'),
              _th('Dimensi/Format'),
              _th('Konteks'),
              _th('Soal'),
              _th('Pilihan Jawaban'),
              _th('Aksi'),
            ],
          ),
          ...list.map((soal) => TableRow(
                children: [
                  _tdPartNo(soal),
                  _tdDimensiFormat(soal),
                  _td(soal.konteks ?? '—',
                      muted: soal.konteks == null),
                  _tdSoal(soal),
                  _tdPilihan(soal),
                  _tdAksi(context, soal),
                ],
              )),
        ],
      ),
    );
  }

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
      );

  Widget _td(String text, {bool muted = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                color: muted
                    ? Colors.grey.shade400
                    : const Color(0xFF374151))),
      );

  Widget _tdPartNo(SoalSternberg soal) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('P${soal.noPart}·${soal.noSoal}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      );

  Widget _tdDimensiFormat(SoalSternberg soal) {
    final dc = _dimensiColor[soal.dimensi] ?? Colors.grey;
    final fc = _formatColor[soal.format] ?? Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniChip(soal.dimensi.label, dc),
          const SizedBox(height: 4),
          _miniChip(soal.format.label, fc),
        ],
      ),
    );
  }

  Widget _miniChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color)),
      );

  Widget _tdSoal(SoalSternberg soal) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(soal.pernyataan,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF111827))),
            if (soal.gambarSoalUrl != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.image_outlined,
                    size: 13, color: Colors.blue),
                const SizedBox(width: 4),
                Text('Ada gambar',
                    style: TextStyle(
                        fontSize: 11, color: Colors.blue.shade600)),
              ]),
            ],
          ],
        ),
      );

  Widget _tdPilihan(SoalSternberg soal) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: soal.pilihan.map((p) {
            final isBenar = p.huruf == soal.jawabanBenar;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Container(
                    width: 17,
                    height: 17,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isBenar
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      border: Border.all(
                          color: isBenar
                              ? Colors.green
                              : Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(p.huruf,
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: isBenar
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.gambarUrl != null ? '🖼 ${p.teks}' : p.teks,
                      style: TextStyle(
                          fontSize: 11,
                          color: isBenar
                              ? Colors.green.shade700
                              : const Color(0xFF374151),
                          fontWeight: isBenar
                              ? FontWeight.w500
                              : FontWeight.w400),
                    ),
                  ),
                  if (isBenar)
                    const Icon(Icons.check_circle_rounded,
                        size: 12, color: Colors.green),
                ],
              ),
            );
          }).toList(),
        ),
      );

  Widget _tdAksi(BuildContext context, SoalSternberg soal) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showEditDialog(context, soal),
              icon: const Icon(Icons.edit_outlined, size: 16),
              color: Colors.blue,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: () => _hapusSoal(context, soal),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              color: Colors.red,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              tooltip: 'Hapus',
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _selectedPart != null
                  ? 'Belum ada soal di Part $_selectedPart'
                  : 'Belum ada soal Sternberg',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text('Klik "+ Tambah Soal" untuk menambah',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );

  void _showTambahDialog(BuildContext context) => showDialog(
        context: context,
        builder: (_) => TambahSoalSternbergDialog(
          defaultPart: _selectedPart,
        ),
      );

  void _showEditDialog(BuildContext context, SoalSternberg soal) =>
      showDialog(
        context: context,
        builder: (_) => TambahSoalSternbergDialog(soalEdit: soal),
      );

  Future<void> _hapusSoal(BuildContext context, SoalSternberg soal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Soal'),
        content: Text(
            'Yakin hapus soal Part ${soal.noPart} No.${soal.noSoal}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && soal.docId != null) await _repo.hapus(soal.docId!);
  }
}
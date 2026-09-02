import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_riasec_model.dart';
import 'package:adminkarieku/features/manajemen_tes/data/repositories/soal_riasec_repository.dart';
import 'tambah_soal_riasec_likert_dialog.dart';

class TabRiasecLikert extends StatelessWidget {
  const TabRiasecLikert({super.key});

  static final _repo = SoalRiasecRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SoalRiasec>>(
      stream: _repo.streamSoalByMetode(MetodeSoal.likert),
      builder: (context, snap) {
        final soalList = snap.data ?? [];
        final isLoading = snap.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soal RIASEC — Skala Likert',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mahasiswa menilai pernyataan skala 1 (Sangat Tidak Setuju) – 5 (Sangat Setuju)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${soalList.length} soal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showTambahDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah Soal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sidebarAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legenda skala Likert
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                children: [
                  _legendChip('1', 'Sangat Tidak Setuju', Colors.red),
                  _legendChip('2', 'Tidak Setuju', Colors.orange),
                  _legendChip('3', 'Netral', Colors.amber),
                  _legendChip('4', 'Setuju', Colors.lightGreen),
                  _legendChip('5', 'Sangat Setuju', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // ── Tabel ───────────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : soalList.isEmpty
                      ? _buildEmptyState()
                      : _buildTable(context, soalList),
            ),
          ],
        );
      },
    );
  }

  Widget _legendChip(String angka, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          '$angka = $label',
          style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500),
        ),
      );

  Widget _buildTable(BuildContext context, List<SoalRiasec> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        columnWidths: const {
          0: FixedColumnWidth(44),
          1: FlexColumnWidth(5),
          2: FixedColumnWidth(80),
          3: FixedColumnWidth(80),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: [
              _th('No'),
              _th('Pernyataan'),
              _th('Tipe RIASEC'),
              _th('Aksi'),
            ],
          ),
          ...list.map((soal) => TableRow(
                children: [
                  _td(soal.no.toString(), center: true),
                  _td(soal.pernyataan),
                  _tdBadge(soal.tipe),
                  _tdAksi(context, soal),
                ],
              )),
        ],
      ),
    );
  }

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
      );

  Widget _td(String text, {bool center = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 13)),
      );

  Widget _tdBadge(String tipe) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _tipeColor(tipe).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(tipe,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tipeColor(tipe))),
          ),
        ),
      );

  Widget _tdAksi(BuildContext context, SoalRiasec soal) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showEditDialog(context, soal),
              icon: const Icon(Icons.edit_outlined, size: 16),
              color: Colors.blue,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              onPressed: () => _hapusSoal(context, soal),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              color: Colors.red,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada soal Likert',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Klik "+ Tambah Soal" untuk menambah',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );

  Color _tipeColor(String tipe) {
    const map = {
      'R': Color(0xFF16A34A),
      'I': Color(0xFF2563EB),
      'A': Color(0xFFD97706),
      'S': Color(0xFF9333EA),
      'E': Color(0xFFDC2626),
      'C': Color(0xFF0891B2),
    };
    return map[tipe] ?? Colors.grey;
  }

  void _showTambahDialog(BuildContext context) => showDialog(
      context: context, builder: (_) => const TambahSoalRiasecLikertDialog());

  void _showEditDialog(BuildContext context, SoalRiasec soal) => showDialog(
      context: context,
      builder: (_) => TambahSoalRiasecLikertDialog(soalEdit: soal));

  Future<void> _hapusSoal(BuildContext context, SoalRiasec soal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Soal'),
        content: Text('Yakin hapus soal no. ${soal.no}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && soal.docId != null) await _repo.hapus(soal.docId!);
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_riasec_model.dart';
import 'package:adminkarieku/features/manajemen_tes/data/repositories/soal_riasec_repository.dart';
import 'tambah_soal_riasec_paired_dialog.dart';

class TabRiasecPaired extends StatelessWidget {
  const TabRiasecPaired({super.key});

  static final _repo = SoalRiasecRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SoalRiasec>>(
      stream: _repo.streamSoalByMetode(MetodeSoal.pairedComparison),
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
                        'Soal RIASEC — Paired Comparison',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mahasiswa memilih pernyataan A atau B yang paling sesuai',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Badge jumlah soal
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${soalList.length} soal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol tambah soal
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

  Widget _buildTable(BuildContext context, List<SoalRiasec> list) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
        columnWidths: const {
          0: FixedColumnWidth(44),
          1: FlexColumnWidth(3),
          2: FixedColumnWidth(64),
          3: FlexColumnWidth(3),
          4: FixedColumnWidth(64),
          5: FixedColumnWidth(80),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: [
              _th('No'),
              _th('Pernyataan A'),
              _th('Tipe A'),
              _th('Pernyataan B'),
              _th('Tipe B'),
              _th('Aksi'),
            ],
          ),
          // Rows
          ...list.map((soal) => TableRow(
                children: [
                  _td(soal.no.toString(), center: true),
                  _td(soal.pernyataanA),
                  _tdBadge(soal.tipeA),
                  _td(soal.pernyataanB),
                  _tdBadge(soal.tipeB),
                  _tdAksi(context, soal),
                ],
              )),
        ],
      ),
    );
  }

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280)),
        ),
      );

  Widget _td(String text, {bool center = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 13),
        ),
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
            child: Text(
              tipe,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _tipeColor(tipe),
              ),
            ),
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
              tooltip: 'Edit',
              color: Colors.blue,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              onPressed: () => _hapusSoal(context, soal),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              tooltip: 'Hapus',
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
            Text(
              'Belum ada soal',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Klik "+ Tambah Soal" untuk menambah',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
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

  void _showTambahDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const TambahSoalRiasecPairedDialog(),
    );
  }

  void _showEditDialog(BuildContext context, SoalRiasec soal) {
    showDialog(
      context: context,
      builder: (_) => TambahSoalRiasecPairedDialog(soalEdit: soal),
    );
  }

  Future<void> _hapusSoal(BuildContext context, SoalRiasec soal) async {
    final konfirmasi = await showDialog<bool>(
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
    if (konfirmasi == true && soal.docId != null) {
      await _repo.hapus(soal.docId!);
    }
  }
}

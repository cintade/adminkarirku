import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_disc_model.dart';
import 'package:adminkarieku/features/manajemen_tes/data/repositories/soal_disc_repository.dart';
import 'tambah_soal_disc_dialog.dart';

class TabDisc extends StatelessWidget {
  const TabDisc({super.key});

  static final _repo = SoalDiscRepository();

  // Warna per dimensi DISC
  static const _discColors = {
    'D': Color(0xFFDC2626),
    'I': Color(0xFFD97706),
    'S': Color(0xFF16A34A),
    'C': Color(0xFF2563EB),
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SoalDisc>>(
      stream: _repo.streamSoal(),
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
                        'Soal DISC — Most & Least',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mahasiswa pilih kata yang PALING (most) dan PALING TIDAK (least) menggambarkan dirinya',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Badge total soal
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${soalList.length} soal',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600),
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
            const SizedBox(height: 12),
            // Legenda DISC
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _discLegend('D', 'Dominance'),
                  const SizedBox(width: 8),
                  _discLegend('I', 'Influence'),
                  const SizedBox(width: 8),
                  _discLegend('S', 'Steadiness'),
                  const SizedBox(width: 8),
                  _discLegend('C', 'Conscientiousness'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // ── List Soal ────────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : soalList.isEmpty
                      ? _buildEmptyState()
                      : _buildListSoal(context, soalList),
            ),
          ],
        );
      },
    );
  }

  Widget _discLegend(String singkatan, String label) {
    final color = _discColors[singkatan] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text('$singkatan – $label',
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildListSoal(BuildContext context, List<SoalDisc> list) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildSoalCard(context, list[i]),
    );
  }

  Widget _buildSoalCard(BuildContext context, SoalDisc soal) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      soal.no.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                    'Pilih kata yang paling / paling tidak menggambarkan Anda',
                    style: TextStyle(fontSize: 13, color: Color(0xFF374151))),
                const Spacer(),
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
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Kata sifat grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: soal.kataSifat.map((kata) {
                final color =
                    _discColors[kata.dimensi.singkatan] ?? Colors.grey;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Column(
                        children: [
                          // Kata sifat
                          Text(
                            kata.teks,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Badge dimensi
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              kata.dimensi.singkatan,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tombol Most / Least (preview UI mobile)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _previewBtn('M', Colors.green),
                              const SizedBox(width: 4),
                              _previewBtn('L', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBtn(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.w700)),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_view_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada soal DISC',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Klik "+ Tambah Soal" untuk menambah',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );

  void _showTambahDialog(BuildContext context) => showDialog(
      context: context, builder: (_) => const TambahSoalDiscDialog());

  void _showEditDialog(BuildContext context, SoalDisc soal) => showDialog(
      context: context, builder: (_) => TambahSoalDiscDialog(soalEdit: soal));

  Future<void> _hapusSoal(BuildContext context, SoalDisc soal) async {
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

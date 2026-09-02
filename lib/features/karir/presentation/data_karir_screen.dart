import 'package:flutter/material.dart';
import 'package:adminkarieku/features/karir/data/karir_model.dart';
import 'package:adminkarieku/features/karir/data/karir_repository.dart';
import 'edit_karir_screen.dart';

class DataKarirScreen extends StatefulWidget {
  const DataKarirScreen({super.key});

  @override
  State<DataKarirScreen> createState() => _DataKarirScreenState();
}

class _DataKarirScreenState extends State<DataKarirScreen> {
  final _repo = KarirRepository();
  final _searchCtrl = TextEditingController();
  String _keyword = '';
  // Catatan: filter RIASEC dihapus dari sini karena RIASEC sekarang
  // adalah bagian dari aturan_rekomendasi (1 karir bisa punya banyak
  // aturan dengan RIASEC berbeda), bukan lagi atribut langsung di karir.

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<KarirModel> _filter(List<KarirModel> list) {
    return list.where((k) {
      final matchSearch = _keyword.isEmpty ||
          k.nama.toLowerCase().contains(_keyword.toLowerCase());
      return matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<List<KarirModel>>(
              stream: _repo.streamKarir(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filtered = _filter(snap.data!);
                if (filtered.isEmpty) {
                  return _buildEmpty();
                }
                return _buildGrid(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Data Karir',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              // Tombol Tambah
              ElevatedButton.icon(
                onPressed: () => _openEdit(context, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Karir',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search + Filter
          Row(
            children: [
              // Search
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _keyword = v),
                  decoration: InputDecoration(
                    hintText: 'Cari nama karir...',
                    hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF9E9E9E), size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<KarirModel> list) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 16.0;
          const columns = 3;
          final cardWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: list
                .map(
                  (k) => SizedBox(
                    width: cardWidth,
                    child: _KarirCard(
                      karir: k,
                      onEdit: () => _openEdit(context, k),
                      onHapus: () => _konfirmasiHapus(context, k),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada data karir',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik "+ Tambah Karir" untuk menambahkan',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context, KarirModel? karir) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditKarirScreen(karir: karir),
      ),
    );
  }

  void _konfirmasiHapus(BuildContext context, KarirModel karir) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Karir',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Yakin ingin menghapus karir "${karir.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF757575))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _repo.hapus(karir.docId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Karir berhasil dihapus'),
                      backgroundColor: Color(0xFF43A047),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: const Color(0xFFE53935),
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Card Karir ───────────────────────────────────────────────────────────────
class _KarirCard extends StatelessWidget {
  final KarirModel karir;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _KarirCard({
    required this.karir,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (karir.rataRataKesiapan * 100).round();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: emoji + jumlah mahasiswa ──
            Row(
              children: [
                Text(karir.emoji, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${karir.jumlahMahasiswa} mahasiswa',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Nama ──
            Text(
              karir.nama,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),

            // ── Deskripsi ──
            Text(
              karir.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF757575), height: 1.4),
            ),
            const SizedBox(height: 10),

            // ── Badge Segment Karir (ganti badge RIASEC) ──
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                karir.karirSegment1,
                karir.karirSegment2,
                karir.karirSegment3,
              ].where((s) => s.isNotEmpty).map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5E35B1),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Rata-rata kesiapan',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                const Spacer(),
                Text('$pct%',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: karir.rataRataKesiapan,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A2E)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),

            // ── Tombol Edit + Hapus ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBDBDBD)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Edit',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onHapus,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF9A9A)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                  child: const Text('Hapus',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE53935))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

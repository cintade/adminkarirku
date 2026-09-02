import 'package:flutter/material.dart';
import 'package:adminkarieku/features/karir/data/karir_model.dart';
import 'package:adminkarieku/features/karir/data/karir_repository.dart';
import 'package:adminkarieku/features/aturan_rekomendasi_karir/data/aturan_rekomendasi_model.dart';
import 'package:adminkarieku/features/aturan_rekomendasi_karir/data/aturan_rekomendasi_repository.dart';
import 'edit_aturan_rekomendasi_screen.dart';

class AturanRekomendasiListScreen extends StatefulWidget {
  const AturanRekomendasiListScreen({super.key});

  @override
  State<AturanRekomendasiListScreen> createState() =>
      _AturanRekomendasiListScreenState();
}

class _AturanRekomendasiListScreenState
    extends State<AturanRekomendasiListScreen> {
  final _repo = AturanRekomendasiRepository();
  final _karirRepo = KarirRepository();
  final _searchCtrl = TextEditingController();

  Map<String, String> _namaKarirById = {};
  bool _loadingKarir = true;
  String _kataKunci = '';

  @override
  void initState() {
    super.initState();
    _loadNamaKarir();
    _searchCtrl.addListener(() {
      setState(() => _kataKunci = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNamaKarir() async {
    final list = await _karirRepo.getDaftarKarirRingkas();
    if (mounted) {
      setState(() {
        _namaKarirById = {for (final k in list) k['id']!: k['nama']!};
        _loadingKarir = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: _loadingKarir
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<AturanRekomendasiModel>>(
                    stream: _repo.streamSemua(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var list = snap.data!;
                      if (_kataKunci.isNotEmpty) {
                        list = list.where((a) {
                          final nama =
                              (_namaKarirById[a.krId] ?? '').toLowerCase();
                          return nama.contains(_kataKunci) ||
                              a.kodePasangan.toLowerCase().contains(_kataKunci);
                        }).toList();
                      }
                      if (list.isEmpty) return _buildEmpty();
                      return _buildListWithHeader(list);
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aturan Rekomendasi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kombinasi RIASEC, DISC, dan bakat yang memicu rekomendasi karir',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8A8A9E)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openEdit(context, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Aturan',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C3FE0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: const InputDecoration(
          hintText: 'Cari nama karir atau kode RIASEC (mis. RI)...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFFB0B0C0)),
          prefixIcon:
              Icon(Icons.search_rounded, size: 20, color: Color(0xFFB0B0C0)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _kataKunci.isEmpty
                ? 'Belum ada aturan rekomendasi'
                : 'Tidak ada aturan yang cocok dengan pencarian',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            _kataKunci.isEmpty
                ? 'Klik "Tambah Aturan" untuk menambahkan'
                : 'Coba kata kunci lain',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // Flex ratio dipakai bersama antara header kolom & baris data supaya sejajar.
  static const _flexPrioritas = 1;
  static const _flexKarir = 3;
  static const _flexRiasec = 3;
  static const _flexDisc = 2;
  static const _flexBakat = 2;
  static const _flexJenjang = 2;

  Widget _buildListWithHeader(List<AturanRekomendasiModel> list) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 8),
          child: Row(
            children: [
              const SizedBox(width: 32 + 16), // ruang utk badge prioritas bulat
              _kolomHeader('Karir', _flexKarir),
              _kolomHeader('RIASEC', _flexRiasec),
              _kolomHeader('DISC', _flexDisc),
              _kolomHeader('Bakat', _flexBakat),
              _kolomHeader('Jenjang', _flexJenjang),
              const SizedBox(width: 88), // ruang utk tombol aksi
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            itemCount: list.length,
            itemBuilder: (context, i) => _buildCard(list[i]),
          ),
        ),
      ],
    );
  }

  Widget _kolomHeader(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Color(0xFFB0B0C0),
        ),
      ),
    );
  }

  Widget _buildCard(AturanRekomendasiModel a) {
    final namaKarir = _namaKarirById[a.krId] ?? '(karir dihapus)';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          _buildPrioritasBadge(a.prioritasRekomendasi),
          const SizedBox(width: 16),
          Expanded(
            flex: _flexKarir,
            child: Text(
              namaKarir,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: _flexRiasec,
            child: Row(
              children: [
                _buildRiasecChip(a.riasecDominan1),
                const SizedBox(width: 6),
                _buildRiasecChip(a.riasecDominan2),
              ],
            ),
          ),
          Expanded(
            flex: _flexDisc,
            child: _buildDiscBadge(a.tipeDisc),
          ),
          Expanded(
            flex: _flexBakat,
            child: Text(
              '${a.kategoriBakat.emoji} ${a.kategoriBakat.label}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A6E)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: _flexJenjang,
            child: Text(
              a.jenjangPendidikan.label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A6E)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Color(0xFF5A5A6E)),
                  onPressed: () => _openEdit(context, a),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFFE53935)),
                  onPressed: () => _konfirmasiHapus(context, a),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritasBadge(int prioritas) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            prioritas == 1 ? const Color(0xFF4C3FE0) : const Color(0xFFEEEEF5),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$prioritas',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: prioritas == 1 ? Colors.white : const Color(0xFF5A5A6E),
        ),
      ),
    );
  }

  Widget _buildRiasecChip(TipeRiasec t) {
    final warna = Color(t.warnaHex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${t.emoji} ${t.kode}',
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: warna),
      ),
    );
  }

  Widget _buildDiscBadge(TipeDisc t) {
    final warna = Color(t.warnaHex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        t.kode,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: warna),
      ),
    );
  }

  void _openEdit(BuildContext context, AturanRekomendasiModel? aturan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAturanRekomendasiScreen(aturan: aturan),
      ),
    ).then((_) => _loadNamaKarir());
  }

  void _konfirmasiHapus(BuildContext context, AturanRekomendasiModel aturan) {
    final namaKarir = _namaKarirById[aturan.krId] ?? 'karir ini';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Aturan Rekomendasi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Yakin ingin menghapus aturan untuk "$namaKarir"?'),
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
                await _repo.hapus(aturan.docId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aturan berhasil dihapus'),
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

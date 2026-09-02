import 'package:flutter/material.dart';
import '../models/karir_model.dart';
import '../services/admin_mapping_service.dart';
import 'karir_form_screen.dart';

/// Halaman "Data Karir": daftar semua karir dalam bentuk card, dengan
/// pencarian nama dan filter tipe RIASEC. Edit/Tambah mengarah ke
/// [KarirFormScreen] yang sudah disesuaikan dengan struktur data asli.
///
/// Card di sini SENGAJA tidak memakai tinggi tetap (fixed height) untuk
/// menghindari error overflow seperti yang terjadi di halaman lama —
/// tinggi card menyesuaikan isi (deskripsi, chip RIASEC, progress bar, dll).
class KarirListScreen extends StatefulWidget {
  const KarirListScreen({super.key});

  @override
  State<KarirListScreen> createState() => _KarirListScreenState();
}

class _KarirListScreenState extends State<KarirListScreen> {
  final _service = AdminMappingService();

  List<Karir> _allKarir = [];
  bool _loading = true;
  String _search = '';
  String _riasecFilter = 'Semua';

  static const _riasecFilterOptions = ['Semua', 'R', 'I', 'A', 'S', 'E', 'C'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getAllKarir();
    setState(() {
      _allKarir = list;
      _loading = false;
    });
  }

  List<Karir> get _filtered {
    return _allKarir.where((k) {
      final matchSearch = _search.isEmpty || k.nama.toLowerCase().contains(_search);
      final matchRiasec = _riasecFilter == 'Semua' || k.riasec.contains(_riasecFilter);
      return matchSearch && matchRiasec;
    }).toList();
  }

  Future<void> _goToForm({Karir? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => KarirFormScreen(existing: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _hapus(Karir karir) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Karir'),
        content: Text('Yakin ingin menghapus "${karir.nama}"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _service.deleteKarir(karir.karirId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Data Karir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _goToForm(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2559),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Karir'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari nama karir...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _riasecFilter,
                    underline: const SizedBox(),
                    items: _riasecFilterOptions
                        .map((r) => DropdownMenuItem(value: r, child: Text('Tipe RIASEC: $r')))
                        .toList(),
                    onChanged: (v) => setState(() => _riasecFilter = v ?? 'Semua'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Tidak ada karir ditemukan', style: TextStyle(color: Colors.grey[600])),
                ),
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _filtered.map((karir) => _buildCard(karir)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Karir karir) {
    return SizedBox(
      width: 320,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        // Column ini TIDAK dibungkus tinggi tetap, jadi otomatis menyesuaikan
        // isi (mencegah overflow seperti pada halaman lama).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(karir.emoji.isNotEmpty ? karir.emoji : '💼', style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEEFE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${karir.jumlahMahasiswa} mahasiswa',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF2F80ED), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(karir.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              karir.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
            ),
            if (karir.riasec.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: karir.riasec
                    .map((r) => CircleAvatar(
                          radius: 13,
                          backgroundColor: const Color(0xFFE3F8E9),
                          child: Text(r,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF1F9254), fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Rata-rata kesiapan', style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                const Spacer(),
                Text('${karir.rataRataKesiapan}%',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (karir.rataRataKesiapan.clamp(0, 100)) / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFF0F0F5),
                color: const Color(0xFF1B2559),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _goToForm(existing: karir),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _hapus(karir),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                    ),
                    child: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

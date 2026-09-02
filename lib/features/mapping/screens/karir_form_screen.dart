import 'package:flutter/material.dart';
import '../models/mata_kuliah_model.dart';
import '../models/karir_model.dart';
import '../services/admin_mapping_service.dart';
import 'package:adminkarieku/features/mapping/widgets/chip_selector.dart';

/// Halaman "Tambah Karir Baru" / "Edit Karir", disesuaikan dengan ERD:
/// karir_id, karir_nama, karir_deskripsi, skill_utama, mk_pendukung,
/// dan "karir_segment1-3" — yang pada implementasi nyata berupa 3
/// sistem klasifikasi karir: RIASEC, DISC, dan Sternberg (field
/// `riasec`, `disc`, `sternberg` di Firestore).
///
/// `karir_id` pada ERD diwakili oleh Firestore Document ID (konsisten
/// dengan keputusan sebelumnya untuk collection ini — tidak ada field
/// karir_id terpisah di data asli). `tanggal_tes` pada ERD TIDAK
/// dimasukkan ke form ini karena itu kemungkinan field milik entity
/// hasil tes yang "terhubung" ke karir, bukan field milik karir itu
/// sendiri.
class KarirFormScreen extends StatefulWidget {
  /// Isi dengan data karir yang sudah ada untuk mode EDIT.
  /// Kosongkan (null) untuk mode TAMBAH.
  final Karir? existing;

  const KarirFormScreen({super.key, this.existing});

  @override
  State<KarirFormScreen> createState() => _KarirFormScreenState();
}

class _KarirFormScreenState extends State<KarirFormScreen> {
  final _service = AdminMappingService();

  late TextEditingController _namaCtrl;
  late TextEditingController _emojiCtrl;
  late TextEditingController _deskripsiCtrl;

  late List<TextEditingController> _skillCtrls;
  late List<String> _selectedRiasec;
  late List<String> _selectedDisc;
  late String? _sternberg;
  late List<String> _mkPendukung;

  List<MataKuliah> _allMk = [];
  bool _loadingMk = true;
  bool _saving = false;

  static const _riasecOptions = [
    MapEntry('R', 'R — Realistic'),
    MapEntry('I', 'I — Investigative'),
    MapEntry('A', 'A — Artistic'),
    MapEntry('S', 'S — Social'),
    MapEntry('E', 'E — Enterprising'),
    MapEntry('C', 'C — Conventional'),
  ];

  static const _discOptions = [
    MapEntry('D', 'D — Dominance'),
    MapEntry('I', 'I — Influence'),
    MapEntry('S', 'S — Steadiness'),
    MapEntry('C', 'C — Conscientiousness'),
  ];

  // Tipe triarchic Sternberg yang umum dipakai. Sesuaikan kalau project
  // kamu memakai istilah/daftar yang berbeda.
  static const _sternbergOptions = [
    MapEntry('analitis', 'Analitis'),
    MapEntry('praktis', 'Praktis'),
    MapEntry('kreatif', 'Kreatif'),
  ];

  @override
  void initState() {
    super.initState();
    final k = widget.existing;
    _namaCtrl = TextEditingController(text: k?.nama ?? '');
    _emojiCtrl = TextEditingController(text: k?.emoji ?? '');
    _deskripsiCtrl = TextEditingController(text: k?.deskripsi ?? '');
    _skillCtrls = (k?.skillUtama.isNotEmpty == true)
        ? k!.skillUtama.map((s) => TextEditingController(text: s)).toList()
        : [TextEditingController()];
    _selectedRiasec = List<String>.from(k?.riasec ?? const []);
    _selectedDisc = List<String>.from(k?.disc ?? const []);
    _sternberg = (k?.sternberg.isNotEmpty == true) ? k!.sternberg : null;
    _mkPendukung = List<String>.from(k?.mkPendukung ?? const []);
    _loadMataKuliah();
  }

  Future<void> _loadMataKuliah() async {
    final list = await _service.getAllMataKuliah();
    setState(() {
      _allMk = list;
      _loadingMk = false;
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emojiCtrl.dispose();
    _deskripsiCtrl.dispose();
    for (final c in _skillCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_namaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama karir wajib diisi')),
      );
      return;
    }

    setState(() => _saving = true);
    final data = {
      'nama': _namaCtrl.text.trim(),
      'deskripsi': _deskripsiCtrl.text.trim(),
      'emoji': _emojiCtrl.text.trim(),
      'sternberg': _sternberg ?? '',
      'riasec': _selectedRiasec,
      'disc': _selectedDisc,
      'skill_utama': _skillCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'mk_pendukung': _mkPendukung,
    };

    try {
      if (widget.existing != null) {
        await _service.updateKarir(widget.existing!.karirId, data);
      } else {
        await _service.addKarir(data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan karir: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: Column(
        children: [
          _buildHeader(isEdit),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final left = _buildLeftColumn();
                  final right = _buildRightColumn();
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 20),
                        Expanded(child: right),
                      ],
                    );
                  }
                  return Column(
                      children: [left, const SizedBox(height: 20), right]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9E9F0))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Text(
            isEdit ? 'Edit Karir' : 'Tambah Karir Baru',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2559),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F7FB),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ---------------- Kolom kiri ----------------
  Widget _buildLeftColumn() {
    return Column(
      children: [
        _card(
          title: 'Informasi Dasar',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama Karir', style: TextStyle(fontSize: 12.5)),
              const SizedBox(height: 6),
              TextField(
                  controller: _namaCtrl,
                  decoration: _fieldDecoration('Masukkan nama karir...')),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Emoji/Ikon',
                            style: TextStyle(fontSize: 12.5)),
                        const SizedBox(height: 6),
                        TextField(
                            controller: _emojiCtrl,
                            decoration: _fieldDecoration('🙂')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sternberg Dominan',
                            style: TextStyle(fontSize: 12.5)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _sternberg,
                          decoration: _fieldDecoration('Pilih tipe dominan'),
                          items: _sternbergOptions
                              .map((o) => DropdownMenuItem(
                                  value: o.key, child: Text(o.value)))
                              .toList(),
                          onChanged: (v) => setState(() => _sternberg = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Deskripsi', style: TextStyle(fontSize: 12.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                decoration:
                    _fieldDecoration('Deskripsi singkat tentang karir ini...'),
              ),
            ],
          ),
        ),
        _card(
          title: 'Skill Utama',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(_skillCtrls.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillCtrls[i],
                          decoration: _fieldDecoration('Skill ${i + 1}...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _skillCtrls.length == 1
                            ? null
                            : () => setState(() {
                                  _skillCtrls[i].dispose();
                                  _skillCtrls.removeAt(i);
                                }),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _skillCtrls.add(TextEditingController())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Skill'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Kolom kanan ----------------
  Widget _buildRightColumn() {
    final mkBelumDipilih =
        _allMk.where((mk) => !_mkPendukung.contains(mk.mkNama)).toList();

    return Column(
      children: [
        _card(
          title: 'Tipe RIASEC yang Cocok',
          child: ChipSelector(
            options: _riasecOptions,
            selected: _selectedRiasec,
            onChanged: (v) => setState(() => _selectedRiasec = v),
          ),
        ),
        _card(
          title: 'MK Pendukung',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingMk)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else
                DropdownButtonFormField<String>(
                  value: null,
                  decoration: _fieldDecoration('+ Tambah MK Pendukung'),
                  items: mkBelumDipilih
                      .map((mk) => DropdownMenuItem(
                          value: mk.mkNama, child: Text(mk.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _mkPendukung.add(v));
                  },
                ),
              if (_mkPendukung.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _mkPendukung
                      .map((nama) => Chip(
                            label: Text(nama),
                            onDeleted: () =>
                                setState(() => _mkPendukung.remove(nama)),
                            backgroundColor: const Color(0xFFEDEBFF),
                            labelStyle: const TextStyle(
                                color: Color(0xFF5B4FE5), fontSize: 12.5),
                            deleteIconColor: const Color(0xFF5B4FE5),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                Text(
                  'Urutan chip = urutan prioritas (mengikuti urutan ditambahkan). '
                  'Bisa diatur ulang lewat halaman "Mapping MK — Profesi".',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
        _card(
          title: 'DISC Dominan',
          child: ChipSelector(
            options: _discOptions,
            selected: _selectedDisc,
            onChanged: (v) => setState(() => _selectedDisc = v),
          ),
        ),
      ],
    );
  }
}

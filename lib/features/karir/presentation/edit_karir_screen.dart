import 'package:flutter/material.dart';
import 'package:adminkarieku/features/karir/data/karir_model.dart';
import 'package:adminkarieku/features/karir/data/karir_repository.dart';

// CATATAN PERUBAHAN (sinkron dengan ERD):
// - Card "Tipe RIASEC yang Cocok", "DISC Dominan", "Sternberg STAT" DIHAPUS
//   dari sini karena field itu sudah pindah ke entity aturan_rekomendasi.
//   Pengaturan RIASEC/DISC/Sternberg untuk karir ini sekarang dilakukan di
//   halaman "Aturan Rekomendasi", bukan lagi di form karir.
// - Card baru "Segment Karir" ditambahkan untuk mengisi karir_segment1-3
//   (jenjang karir, misal Junior / Mid / Senior).

class EditKarirScreen extends StatefulWidget {
  final KarirModel? karir;
  const EditKarirScreen({super.key, this.karir});

  @override
  State<EditKarirScreen> createState() => _EditKarirScreenState();
}

class _EditKarirScreenState extends State<EditKarirScreen> {
  final _repo = KarirRepository();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  List<String> _daftarMK = [];

  // ── Controllers ──
  late final TextEditingController _namaCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _idCtrl;

  // ── State ──
  List<TextEditingController> _skillCtrls = [];
  List<String> _mkDipilih = [];
  late final TextEditingController _segment1Ctrl;
  late final TextEditingController _segment2Ctrl;
  late final TextEditingController _segment3Ctrl;
  String? _idError; // pesan error validasi ID (mis. "sudah dipakai")
  bool _cekingId = false;

  @override
  void initState() {
    super.initState();
    final k = widget.karir;
    _namaCtrl = TextEditingController(text: k?.nama ?? '');
    _emojiCtrl = TextEditingController(text: k?.emoji ?? '💼');
    _deskripsiCtrl = TextEditingController(text: k?.deskripsi ?? '');
    _idCtrl = TextEditingController(text: k?.docId ?? '');
    _mkDipilih = List.from(k?.mkPendukung ?? []);
    _segment1Ctrl = TextEditingController(text: k?.karirSegment1 ?? '');
    _segment2Ctrl = TextEditingController(text: k?.karirSegment2 ?? '');
    _segment3Ctrl = TextEditingController(text: k?.karirSegment3 ?? '');

    // Skill controllers
    final skills = k?.skillUtama ?? [''];
    _skillCtrls = skills.map((s) => TextEditingController(text: s)).toList();
    if (_skillCtrls.isEmpty) {
      _skillCtrls.add(TextEditingController());
    }

    _loadMK();
  }

  Future<void> _loadMK() async {
    final list = await _repo.getDaftarMK();
    if (mounted) setState(() => _daftarMK = list);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emojiCtrl.dispose();
    _deskripsiCtrl.dispose();
    _idCtrl.dispose();
    for (final c in _skillCtrls) {
      c.dispose();
    }
    _segment1Ctrl.dispose();
    _segment2Ctrl.dispose();
    _segment3Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.karir != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 14, color: Color(0xFF1A1A2E)),
          label: const Text('← Kembali',
              style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 13)),
        ),
        leadingWidth: 120,
        title: Text(
          isEdit ? 'Edit Karir — ${widget.karir!.nama}' : 'Tambah Karir Baru',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: ElevatedButton(
              onPressed: _loading ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Kolom Kiri ──
              Expanded(
                child: Column(
                  children: [
                    _buildInfoDasar(),
                    const SizedBox(height: 20),
                    _buildSkillUtama(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // ── Kolom Kanan ──
              Expanded(
                child: Column(
                  children: [
                    _buildMKPendukung(),
                    const SizedBox(height: 20),
                    _buildSegmentKarir(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CARD: Informasi Dasar ─────────────────────────────────────────────────
  Widget _buildInfoDasar() {
    final isEdit = widget.karir != null;
    return _Card(
      title: 'Informasi Dasar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID Karir (Document ID) — hanya bisa diisi saat tambah baru.
          // Saat edit, ID tidak boleh diubah (Firestore tidak bisa rename
          // document id), jadi ditampilkan read-only.
          _Label('ID Karir'),
          if (isEdit)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _idCtrl.text,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF757575)),
                    ),
                  ),
                  const Icon(Icons.lock_outline_rounded,
                      size: 14, color: Color(0xFF9E9E9E)),
                ],
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _idCtrl,
                    decoration:
                        _inputDeco('mis. karir_software_engineer').copyWith(
                      errorText: _idError,
                      suffixIcon: _cekingId
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (_) {
                      // reset error tiap kali user ngetik ulang, akan
                      // divalidasi ulang saat _simpan()
                      if (_idError != null) setState(() => _idError = null);
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return null; // opsional
                      final valid = RegExp(r'^[a-z0-9_]+$').hasMatch(v.trim());
                      if (!valid) {
                        return 'Hanya huruf kecil, angka, dan underscore';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    final generated = _repo.generateIdDariNama(_namaCtrl.text);
                    setState(() {
                      _idCtrl.text = generated;
                      _idError = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBDBDBD)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                  ),
                  child: const Text('Generate',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E))),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Kosongkan untuk auto-ID dari Firestore.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Nama Karir
          _Label('Nama Karir'),
          TextFormField(
            controller: _namaCtrl,
            decoration: _inputDeco('Masukkan nama karir...'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 16),

          // Emoji
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Emoji/Ikon'),
                TextFormField(
                  controller: _emojiCtrl,
                  decoration: _inputDeco('💼'),
                  style: const TextStyle(fontSize: 24),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Emoji wajib diisi'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Deskripsi
          _Label('Deskripsi'),
          TextFormField(
            controller: _deskripsiCtrl,
            maxLines: 4,
            decoration: _inputDeco('Deskripsi singkat tentang karir ini...'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
          ),
        ],
      ),
    );
  }

  // ─── CARD: Skill Utama ─────────────────────────────────────────────────────
  Widget _buildSkillUtama() {
    return _Card(
      title: 'Skill Utama',
      child: Column(
        children: [
          ..._skillCtrls.asMap().entries.map((entry) {
            final i = entry.key;
            final ctrl = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ctrl,
                      decoration: _inputDeco('Skill ${i + 1}...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _skillCtrls.length > 1
                        ? () {
                            setState(() {
                              _skillCtrls[i].dispose();
                              _skillCtrls.removeAt(i);
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      color: _skillCtrls.length > 1
                          ? const Color(0xFFE53935)
                          : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            );
          }),
          // Tombol tambah skill
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _skillCtrls.add(TextEditingController())),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('+ Tambah Skill'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBDBDBD)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD: MK Pendukung ────────────────────────────────────────────────────
  Widget _buildMKPendukung() {
    return _Card(
      title: 'MK Pendukung',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daftar MK yang sudah dipilih
          ..._mkDipilih.map((mk) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(mk, style: const TextStyle(fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _mkDipilih.remove(mk)),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Color(0xFFE53935)),
                      ),
                    ),
                  ],
                ),
              )),

          // Dropdown tambah MK
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: null,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16, color: Color(0xFF9E9E9E)),
                      SizedBox(width: 6),
                      Text('+ Tambah MK Pendukung',
                          style: TextStyle(
                              color: Color(0xFF9E9E9E), fontSize: 13)),
                    ],
                  ),
                ),
                isExpanded: true,
                borderRadius: BorderRadius.circular(8),
                items: _daftarMK
                    .where((mk) => !_mkDipilih.contains(mk))
                    .map((mk) => DropdownMenuItem(value: mk, child: Text(mk)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _mkDipilih.add(v));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CARD: Segment Karir ───────────────────────────────────────────────────
  // Sesuai ERD: karir_segment1-3 -> 3 jenjang/level karir ini
  // (misal: Junior -> Mid -> Senior). Boleh dikosongkan jika belum relevan.
  Widget _buildSegmentKarir() {
    final segmentData = [
      ('Segment 1 (Junior)', _segment1Ctrl),
      ('Segment 2 (Mid)', _segment2Ctrl),
      ('Segment 3 (Senior)', _segment3Ctrl),
    ];
    return _Card(
      title: 'Segment Karir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, ctrl) in segmentData) ...[
            _Label(label),
            TextFormField(
              controller: ctrl,
              decoration: _inputDeco('Contoh: Junior $label...'),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // ─── Simpan ke Firebase ────────────────────────────────────────────────────
  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.karir != null;
    final customId = _idCtrl.text.trim();

    // Validasi ketersediaan ID hanya berlaku saat tambah baru & ID diisi.
    if (!isEdit && customId.isNotEmpty) {
      setState(() => _cekingId = true);
      final tersedia = await _repo.cekIdTersedia(customId);
      setState(() => _cekingId = false);
      if (!tersedia) {
        setState(() => _idError = 'ID "$customId" sudah dipakai');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final skills = _skillCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final karir = KarirModel(
        docId: widget.karir?.docId,
        nama: _namaCtrl.text.trim(),
        emoji: _emojiCtrl.text.trim(),
        deskripsi: _deskripsiCtrl.text.trim(),
        skillUtama: skills,
        mkPendukung: _mkDipilih,
        karirSegment1: _segment1Ctrl.text.trim(),
        karirSegment2: _segment2Ctrl.text.trim(),
        karirSegment3: _segment3Ctrl.text.trim(),
        jumlahMahasiswa: widget.karir?.jumlahMahasiswa ?? 0,
        rataRataKesiapan: widget.karir?.rataRataKesiapan ?? 0.0,
      );

      if (isEdit) {
        await _repo.update(widget.karir!.docId!, karir);
      } else {
        await _repo.tambah(
          karir,
          customId: customId.isEmpty ? null : customId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.karir != null
                ? '✅ Karir berhasil diperbarui!'
                : '✅ Karir berhasil ditambahkan!'),
            backgroundColor: const Color(0xFF43A047),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

Widget _Label(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF757575),
      ),
    ),
  );
}

InputDecoration _inputDeco(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}

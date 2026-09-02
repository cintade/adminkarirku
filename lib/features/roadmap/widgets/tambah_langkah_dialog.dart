import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adminkarieku/features/roadmap/data/roadmap_langkah_model.dart';
import 'package:adminkarieku/features/roadmap/data/roadmap_langkah_repository.dart';

class TambahLangkahDialog extends StatefulWidget {
  final RoadmapLangkah? langkahEdit;
  final String? defaultKarierId;

  const TambahLangkahDialog({
    super.key,
    this.langkahEdit,
    this.defaultKarierId, // ← tambah ini
  });

  @override
  State<TambahLangkahDialog> createState() => _TambahLangkahDialogState();
}

class _TambahLangkahDialogState extends State<TambahLangkahDialog> {
  final _repo = RoadmapLangkahRepository();
  final _formKey = GlobalKey<FormState>();

  // ✅ SESUDAH — inisialisasi langsung
  final TextEditingController _karierIdCtrl = TextEditingController();
  final TextEditingController _deskripsiCtrl = TextEditingController();
  final TextEditingController _sumberGapCtrl = TextEditingController();

  KategoriLangkah _kategori = KategoriLangkah.akademik;
  int _targetSmt = 1;
  bool _loading = false;

  // Pilihan sumber gap umum
  static const _sumberGapOptions = [
    'RIASEC',
    'Sternberg',
    'DISC',
    'Nilai MK',
    'Manual',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.langkahEdit;

    // Isi nilai awal setelah controller sudah ada
    _karierIdCtrl.text = s?.karierId ?? widget.defaultKarierId ?? '';
    _deskripsiCtrl.text = s?.deskripsi ?? '';
    _sumberGapCtrl.text = s?.sumberGap ?? '';

    if (s != null) {
      _kategori = s.kategori;
      _targetSmt = s.targetSmt;
    }
  }

  @override
  void dispose() {
    _karierIdCtrl.dispose();
    _deskripsiCtrl.dispose();
    _sumberGapCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.langkahEdit != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildInfoBox(),
                      const SizedBox(height: 20),

                      // ── Karir ID ───────────────────────────────────────────
                      _sectionLabel('ID Karir', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _karierIdCtrl,
                        decoration: _inputDeco(
                          hint: 'Contoh: web_developer, data_analyst',
                          icon: Icons.work_outline_rounded,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Karir ID wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Isi sesuai document ID di collection karir Firestore',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),

                      // ── Deskripsi ──────────────────────────────────────────
                      _sectionLabel('Deskripsi Langkah', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _deskripsiCtrl,
                        maxLines: 3,
                        decoration: _inputDeco(
                          hint:
                              'Contoh: Menyelesaikan mata kuliah Pemrograman Web dengan nilai minimal B',
                          icon: Icons.description_outlined,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Deskripsi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Kategori + Target Semester (row) ───────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kategori
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Kategori', required: true),
                                const SizedBox(height: 6),
                                _buildKategoriPicker(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Target Semester
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Target Semester',
                                    required: true),
                                const SizedBox(height: 6),
                                _buildSemesterPicker(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Sumber Gap ─────────────────────────────────────────
                      _sectionLabel('Sumber Gap', required: true),
                      const SizedBox(height: 6),
                      _buildSumberGapField(),
                      const SizedBox(height: 6),
                      Text(
                        'Dari mana kebutuhan langkah ini teridentifikasi',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.route_rounded,
                size: 18, color: Colors.indigo.shade700),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit Langkah Roadmap' : 'Tambah Langkah Roadmap',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                _isEdit
                    ? 'Perbarui data langkah roadmap karir'
                    : 'Data ini akan tampil di aplikasi mahasiswa',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  // ── Info Box ────────────────────────────────────────────────────────────────
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Langkah yang diinput di sini akan otomatis tersedia di aplikasi '
              'mobile mahasiswa ketika mereka memilih karir yang sesuai. '
              'Pastikan urutan dan target semester sudah tepat.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Kategori Picker ─────────────────────────────────────────────────────────
  Widget _buildKategoriPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KategoriLangkah.values.map((k) {
        final selected = _kategori == k;
        final color = _kategoriColor(k);
        return GestureDetector(
          onTap: () => setState(() => _kategori = k),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? color : Colors.grey.shade200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _kategoriIcon(k),
                  size: 14,
                  color: selected ? color : Colors.grey.shade400,
                ),
                const SizedBox(width: 5),
                Text(
                  k.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? color : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Semester Picker ─────────────────────────────────────────────────────────
  Widget _buildSemesterPicker() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(8, (i) {
          final smt = i + 1;
          final selected = _targetSmt == smt;
          return GestureDetector(
            onTap: () => setState(() => _targetSmt = smt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 38,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? Colors.indigo.shade600 : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      selected ? Colors.indigo.shade600 : Colors.grey.shade200,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.indigo.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '$smt',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Sumber Gap Field ─────────────────────────────────────────────────────────
  Widget _buildSumberGapField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick pick chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _sumberGapOptions.map((opt) {
            final selected = _sumberGapCtrl.text == opt;
            return GestureDetector(
              onTap: () {
                setState(() => _sumberGapCtrl.text = opt);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? Colors.orange.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected
                        ? Colors.orange.shade300
                        : Colors.grey.shade200,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? Colors.orange.shade800
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Manual input
        TextFormField(
          controller: _sumberGapCtrl,
          onChanged: (_) => setState(() {}),
          decoration: _inputDeco(
            hint: 'Atau ketik manual...',
            icon: Icons.analytics_outlined,
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Sumber gap wajib diisi' : null,
        ),
      ],
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _loading ? null : _simpan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Langkah'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.indigo.shade400, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _sectionLabel(String text, {bool required = false}) => Row(
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      );

  Color _kategoriColor(KategoriLangkah k) {
    switch (k) {
      case KategoriLangkah.akademik:
        return const Color(0xFF2563EB);
      case KategoriLangkah.softSkill:
        return const Color(0xFF9333EA);
      case KategoriLangkah.portofolio:
        return const Color(0xFFD97706);
      case KategoriLangkah.sertifikasi:
        return const Color(0xFF0891B2);
      case KategoriLangkah.pengalaman:
        return const Color(0xFF16A34A);
    }
  }

  IconData _kategoriIcon(KategoriLangkah k) {
    switch (k) {
      case KategoriLangkah.akademik:
        return Icons.school_outlined;
      case KategoriLangkah.softSkill:
        return Icons.psychology_outlined;
      case KategoriLangkah.portofolio:
        return Icons.folder_outlined;
      case KategoriLangkah.sertifikasi:
        return Icons.card_membership_outlined;
      case KategoriLangkah.pengalaman:
        return Icons.badge_outlined;
    }
  }

  // ── Simpan ───────────────────────────────────────────────────────────────────
  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final karierId = _karierIdCtrl.text.trim();
      final urutan = _isEdit
          ? widget.langkahEdit!.urutan
          : await _repo.nextUrutan(karierId);

      // Status tidak lagi diatur lewat form ini. Progres langkah yang
      // sebenarnya ada di collection `roadmap_log` (per mahasiswa), bukan
      // di sini. Kalau ini edit langkah lama, nilai status lama dibiarkan
      // apa adanya (tidak ditimpa); kalau langkah baru, pakai default
      // 'belum' dari model.
      final langkah = RoadmapLangkah(
        docId: widget.langkahEdit?.docId,
        karierId: karierId,
        urutan: urutan,
        deskripsi: _deskripsiCtrl.text.trim(),
        kategori: _kategori,
        targetSmt: _targetSmt,
        sumberGap: _sumberGapCtrl.text.trim(),
        status: widget.langkahEdit?.status ?? StatusLangkah.belum,
      );

      if (_isEdit) {
        await _repo.update(langkah.docId!, langkah);
      } else {
        await _repo.tambah(langkah);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? '✅ Langkah berhasil diperbarui'
                : '✅ Langkah berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

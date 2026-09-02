import 'package:flutter/material.dart';
import '../../data/mata_kuliah_model.dart';

// ─── Warna (sesuai app_theme admin) ──────────────────────────────────────────
class _C {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3F2FD);
  static const pageBg = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE8ECF0);
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF6B7A8D);
  static const textMuted = Color(0xFF9AA5B4);
  static const danger = Color(0xFFC62828);
  static const dangerLight = Color(0xFFFFEBEE);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFE65100);
}

class TambahEditMkDialog extends StatefulWidget {
  final MataKuliah? existing; // null = tambah baru
  final List<String> prodiList;

  const TambahEditMkDialog({
    super.key,
    this.existing,
    required this.prodiList,
  });

  @override
  State<TambahEditMkDialog> createState() => _TambahEditMkDialogState();
}

class _TambahEditMkDialogState extends State<TambahEditMkDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _mkIdCtrl;
  late TextEditingController _mkNamaCtrl;
  late TextEditingController _mkDeskripsiCtrl;
  late TextEditingController _seg1Ctrl;
  late TextEditingController _seg2Ctrl;
  late TextEditingController _seg3Ctrl;

  int _mkSks = 3;
  int _mkSemester = 1;
  String _mkProdi = 'TI';
  String _tipe = 'Wajib';

  bool get _isEdit => widget.existing != null;

  static const _tipeOptions = [
    'Wajib',
    'Pilihan Utama',
    'Pilihan',
    'Penunjang',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    final mk = widget.existing;
    _mkIdCtrl = TextEditingController(text: mk?.mkId ?? '');
    _mkNamaCtrl = TextEditingController(text: mk?.mkNama ?? '');
    _mkDeskripsiCtrl = TextEditingController(text: mk?.mkDeskripsi ?? '');
    _seg1Ctrl = TextEditingController(text: mk?.mkSegment1 ?? '');
    _seg2Ctrl = TextEditingController(text: mk?.mkSegment2 ?? '');
    _seg3Ctrl = TextEditingController(text: mk?.mkSegment3 ?? '');
    _mkSks = mk?.mkSks ?? 3;
    _mkSemester = mk?.mkSemester ?? 1;
    _mkProdi = mk?.mkProdi ??
        (widget.prodiList.isNotEmpty ? widget.prodiList.first : 'TI');
    _tipe = mk?.tipe ?? 'Wajib';
  }

  @override
  void dispose() {
    _mkIdCtrl.dispose();
    _mkNamaCtrl.dispose();
    _mkDeskripsiCtrl.dispose();
    _seg1Ctrl.dispose();
    _seg2Ctrl.dispose();
    _seg3Ctrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final mk = MataKuliah(
      docId: widget.existing?.docId,
      mkId: _mkIdCtrl.text.trim().toUpperCase(),
      mkNama: _mkNamaCtrl.text.trim(),
      mkSks: _mkSks,
      mkSemester: _mkSemester,
      mkSegment1: _seg1Ctrl.text.trim(),
      mkSegment2: _seg2Ctrl.text.trim(),
      mkSegment3: _seg3Ctrl.text.trim(),
      mkDeskripsi: _mkDeskripsiCtrl.text.trim(),
      mkProdi: _mkProdi,
      tipe: _tipe,
    );

    Navigator.pop(context, mk);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(),
              const Divider(height: 1, color: _C.border),

              // ── Form Body ────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris 1: Kode MK + Nama MK
                      Row(children: [
                        SizedBox(
                          width: 140,
                          child: _buildField(
                            label: 'Kode MK *',
                            ctrl: _mkIdCtrl,
                            hint: 'IF301',
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildField(
                            label: 'Nama Mata Kuliah *',
                            ctrl: _mkNamaCtrl,
                            hint: 'Pemrograman Web',
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Baris 2: SKS + Semester + Prodi + Tipe
                      Row(children: [
                        SizedBox(
                          width: 100,
                          child: _buildDropdownField<int>(
                            label: 'SKS *',
                            value: _mkSks,
                            items: [1, 2, 3, 4, 6],
                            labelOf: (v) => '$v SKS',
                            onChanged: (v) => setState(() => _mkSks = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: _buildDropdownField<int>(
                            label: 'Semester *',
                            value: _mkSemester,
                            items: List.generate(8, (i) => i + 1),
                            labelOf: (v) => 'Semester $v',
                            onChanged: (v) => setState(() => _mkSemester = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 130,
                          child: _buildDropdownField<String>(
                            label: 'Prodi *',
                            value: widget.prodiList.contains(_mkProdi)
                                ? _mkProdi
                                : (widget.prodiList.isNotEmpty
                                    ? widget.prodiList.first
                                    : 'TI'),
                            items: widget.prodiList.isNotEmpty
                                ? widget.prodiList
                                : ['TI', 'SI', 'MI'],
                            labelOf: (v) => v,
                            onChanged: (v) => setState(() => _mkProdi = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField<String>(
                            label: 'Tipe *',
                            value: _tipe,
                            items: _tipeOptions,
                            labelOf: (v) => v,
                            onChanged: (v) => setState(() => _tipe = v!),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Baris 3: Profesi Relevan (mk_segment1-3)
                      _buildSectionLabel('Profesi Relevan (mk_segment)'),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: _buildField(
                            ctrl: _seg1Ctrl,
                            hint: 'Contoh: Data Scientist',
                            label: 'Segment 1',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            ctrl: _seg2Ctrl,
                            hint: 'Contoh: AI Engineer',
                            label: 'Segment 2',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            ctrl: _seg3Ctrl,
                            hint: 'Contoh: Backend Dev',
                            label: 'Segment 3',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Deskripsi
                      _buildField(
                        label: 'Deskripsi (mk_deskripsi)',
                        ctrl: _mkDeskripsiCtrl,
                        hint: 'Deskripsi singkat mata kuliah...',
                        maxLines: 3,
                      ),

                      // Preview prioritas
                      const SizedBox(height: 16),
                      _buildPrioritasPreview(),
                    ],
                  ),
                ),
              ),

              // ── Footer ───────────────────────────────────────────────────
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book_outlined,
                color: _C.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            _isEdit ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: _C.pageBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _C.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─── Text field ───────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: _C.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: _C.textMuted),
            filled: true,
            fillColor: _C.pageBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _C.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _C.danger),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  // ─── Dropdown field ───────────────────────────────────────────────────────
  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _C.pageBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.contains(value) ? value : items.first,
              onChanged: onChanged,
              isExpanded: true,
              style: const TextStyle(fontSize: 13, color: _C.textPrimary),
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(labelOf(item),
                            style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Preview prioritas ────────────────────────────────────────────────────
  Widget _buildPrioritasPreview() {
    final tempMk = MataKuliah(
      mkId: '',
      mkNama: '',
      mkSks: _mkSks,
      mkSemester: _mkSemester,
      mkProdi: _mkProdi,
      tipe: _tipe,
    );
    final prio = tempMk.prioritas;
    final color = _prioritasColor(prio);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            'Prioritas MK ini: ',
            style: TextStyle(fontSize: 12, color: color),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(prio,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Text(
            '(berdasarkan tipe: $_tipe)',
            style: const TextStyle(fontSize: 11, color: _C.textMuted),
          ),
        ],
      ),
    );
  }

  Color _prioritasColor(String p) {
    switch (p) {
      case 'P5':
        return const Color(0xFF1565C0);
      case 'P4':
        return const Color(0xFFE65100);
      case 'P3':
        return const Color(0xFF2E7D32);
      case 'P2':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF9AA5B4);
    }
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Batal', style: TextStyle(color: _C.textSecondary)),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _C.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _simpan,
            icon: Icon(
              _isEdit ? Icons.save_outlined : Icons.add_rounded,
              size: 16,
            ),
            label: Text(
              _isEdit ? 'Simpan Perubahan' : 'Tambah MK',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

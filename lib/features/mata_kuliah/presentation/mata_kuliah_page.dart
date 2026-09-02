import 'package:flutter/material.dart';
import 'package:adminkarieku/features/mata_kuliah/data/mata_kuliah_model.dart';
import 'package:adminkarieku/features/mata_kuliah/data/mata_kuliah_repository.dart';
import 'package:adminkarieku/features/mata_kuliah/presentation/widgets/tambah_edit_mk_dialog.dart';
import 'package:adminkarieku/features/mata_kuliah/data/import_excel_mk_dialog.dart';

// ─── Warna ────────────────────────────────────────────────────────────────────
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

  static Color prioritasColor(String p) {
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// MATA KULIAH PAGE
// ═══════════════════════════════════════════════════════════════════════════════
class MataKuliahPage extends StatefulWidget {
  const MataKuliahPage({super.key});

  @override
  State<MataKuliahPage> createState() => _MataKuliahPageState();
}

class _MataKuliahPageState extends State<MataKuliahPage> {
  final _repo = MataKuliahRepository();

  // ── State filter & search ─────────────────────────────────────────────────
  List<MataKuliah> _allMk = [];
  List<MataKuliah> _filtered = [];
  List<String> _prodiList = [];
  bool _isLoading = true;
  String _errorMsg = '';
  int _totalAll = 0;

  // Filter
  String _searchQuery = '';
  int? _filterSemester;
  String _filterProdi = '';

  // Pagination
  static const _perPage = 10;
  int _page = 0;
  List<MataKuliah> get _paged {
    final start = _page * _perPage;
    final end = (start + _perPage).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Load data ─────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final results = await Future.wait([
        _repo.getAll(),
        _repo.getProdiList(),
      ]);
      _allMk = results[0] as List<MataKuliah>;
      _prodiList = results[1] as List<String>;
      _totalAll = _allMk.length;
      _applyFilter();
    } catch (e) {
      setState(() => _errorMsg = 'Gagal memuat data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Filter lokal ──────────────────────────────────────────────────────────
  void _applyFilter() {
    List<MataKuliah> result = List.from(_allMk);

    if (_filterSemester != null) {
      result = result.where((m) => m.mkSemester == _filterSemester).toList();
    }
    if (_filterProdi.isNotEmpty) {
      result = result.where((m) => m.mkProdi == _filterProdi).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((m) =>
              m.mkId.toLowerCase().contains(q) ||
              m.mkNama.toLowerCase().contains(q) ||
              m.mkProdi.toLowerCase().contains(q) ||
              m.mkSegment1.toLowerCase().contains(q) ||
              m.mkSegment2.toLowerCase().contains(q))
          .toList();
    }

    setState(() {
      _filtered = result;
      _page = 0;
    });
  }

  // ── Tambah MK ─────────────────────────────────────────────────────────────
  Future<void> _tambah() async {
    final result = await showDialog<MataKuliah>(
      context: context,
      builder: (_) => TambahEditMkDialog(prodiList: _prodiList),
    );
    if (result == null) return;

    try {
      await _repo.tambah(result);
      _showSnackbar('MK "${result.mkNama}" berhasil ditambahkan ✓',
          isError: false);
      await _loadData();
    } catch (e) {
      _showSnackbar('$e', isError: true);
    }
  }

  // ── Edit MK ───────────────────────────────────────────────────────────────
  Future<void> _edit(MataKuliah mk) async {
    final result = await showDialog<MataKuliah>(
      context: context,
      builder: (_) => TambahEditMkDialog(
        existing: mk,
        prodiList: _prodiList,
      ),
    );
    if (result == null) return;

    try {
      await _repo.update(result);
      _showSnackbar('MK "${result.mkNama}" berhasil diupdate ✓',
          isError: false);
      await _loadData();
    } catch (e) {
      _showSnackbar('$e', isError: true);
    }
  }

  // ── Import Excel ──────────────────────────────────────────────────────────
  Future<void> _importExcel() async {
    final existingIds = _allMk.map((m) => m.mkId.toUpperCase()).toSet();

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImportExcelMkDialog(existingMkIds: existingIds),
    );

    if (result == null) return; // dibatalkan

    _showSnackbar('$result mata kuliah berhasil diimport ✓', isError: false);
    await _loadData();
  }

  // ── Hapus MK ──────────────────────────────────────────────────────────────
  Future<void> _hapus(MataKuliah mk) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: _C.textPrimary, fontSize: 14),
            children: [
              const TextSpan(text: 'Yakin ingin menghapus '),
              TextSpan(
                text: '"${mk.mkNama}"',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                  text:
                      '?\n\nData MK yang sudah ditambahkan mahasiswa tidak akan terhapus.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repo.hapus(mk.docId!);
      _showSnackbar('MK "${mk.mkNama}" dihapus', isError: false);
      await _loadData();
    } catch (e) {
      _showSnackbar('Gagal hapus: $e', isError: true);
    }
  }

  void _showSnackbar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _C.danger : _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top Bar ──────────────────────────────────────────────────────
        _TopBar(),
        // ── Konten ───────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _C.primary))
              : _errorMsg.isNotEmpty
                  ? _ErrorView(msg: _errorMsg, onRetry: _loadData)
                  : _buildContent(),
        ),
      ],
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _TopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: _C.cardBg,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          const Text('Mata Kuliah',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary)),
          const Spacer(),
          // Search
          Container(
            width: 240,
            height: 36,
            decoration: BoxDecoration(
              color: _C.pageBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border),
            ),
            child: TextField(
              onChanged: (v) {
                _searchQuery = v;
                _applyFilter();
              },
              style: const TextStyle(fontSize: 13, color: _C.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari mata kuliah...',
                hintStyle: TextStyle(fontSize: 13, color: _C.textMuted),
                prefixIcon: Icon(Icons.search, size: 18, color: _C.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _bulanIni(),
            style: const TextStyle(fontSize: 12, color: _C.textMuted),
          ),
        ],
      ),
    );
  }

  String _bulanIni() {
    final now = DateTime.now();
    const b = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${b[now.month]} ${now.year}';
  }

  // ── Konten utama ──────────────────────────────────────────────────────────
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + tombol aksi
          _buildPageHeader(),
          const SizedBox(height: 20),
          // Filter bar
          _buildFilterBar(),
          const SizedBox(height: 16),
          // Tabel
          _buildTable(),
          const SizedBox(height: 12),
          // Footer pagination
          _buildPagination(),
        ],
      ),
    );
  }

  // ── Page header ───────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manajemen Mata Kuliah',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary)),
            const SizedBox(height: 4),
            Text('Total $_totalAll mata kuliah terdaftar',
                style: const TextStyle(fontSize: 13, color: _C.textSecondary)),
          ],
        ),
        const Spacer(),
        // Import Excel
        OutlinedButton.icon(
          onPressed: _importExcel,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _C.border),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.upload_file_rounded,
              size: 16, color: _C.textSecondary),
          label: const Text('Import Excel',
              style: TextStyle(color: _C.textSecondary)),
        ),
        const SizedBox(width: 12),
        // Tambah MK
        FilledButton.icon(
          onPressed: _tambah,
          style: FilledButton.styleFrom(
            backgroundColor: _C.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('+ Tambah MK',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Row(
      children: [
        // Search field (inline, sudah di top bar)
        // Filter Semester
        _buildFilterDropdown<int?>(
          value: _filterSemester,
          hint: 'Semua Semester',
          items: [null, ...List.generate(8, (i) => i + 1)],
          labelOf: (v) => v == null ? 'Semua Semester' : 'Semester $v',
          onChanged: (v) {
            _filterSemester = v;
            _applyFilter();
          },
        ),
        const SizedBox(width: 12),
        // Filter Prodi
        _buildFilterDropdown<String>(
          value: _filterProdi,
          hint: 'Semua Prodi',
          items: ['', ..._prodiList],
          labelOf: (v) => v.isEmpty ? 'Semua Prodi' : v,
          onChanged: (v) {
            _filterProdi = v ?? '';
            _applyFilter();
          },
        ),
        const Spacer(),
        // Tombol reset filter
        if (_filterSemester != null ||
            _filterProdi.isNotEmpty ||
            _searchQuery.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _filterSemester = null;
                _filterProdi = '';
                _searchQuery = '';
              });
              _applyFilter();
            },
            icon: const Icon(Icons.clear_rounded,
                size: 14, color: _C.textSecondary),
            label: const Text('Reset Filter',
                style: TextStyle(color: _C.textSecondary)),
          ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required String hint,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 13, color: _C.textMuted)),
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: _C.textPrimary),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelOf(item)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Tabel ─────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          // Header tabel
          _TableHeader(),
          const Divider(height: 1, color: _C.border),
          // Rows
          if (_paged.isEmpty)
            _EmptyRow()
          else
            ...List.generate(_paged.length, (i) {
              final mk = _paged[i];
              final isLast = i == _paged.length - 1;
              return Column(
                children: [
                  _TableRow(
                    mk: mk,
                    onEdit: () => _edit(mk),
                    onHapus: () => _hapus(mk),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, color: _C.border, indent: 20, endIndent: 20),
                ],
              );
            }),
          // Footer info
          const Divider(height: 1, color: _C.border),
          _TableFooter(
            showing: _paged.length,
            total: _filtered.length,
            page: _page,
            perPage: _perPage,
          ),
        ],
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _page > 0 ? () => setState(() => _page--) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        ...List.generate(_totalPages, (i) {
          return GestureDetector(
            onTap: () => setState(() => _page = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _page ? _C.primary : _C.cardBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: i == _page ? _C.primary : _C.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: i == _page ? Colors.white : _C.textSecondary,
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed:
              _page < _totalPages - 1 ? () => setState(() => _page++) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

// ─── Header kolom tabel ───────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _C.pageBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 100, child: _HeaderCell('Kode MK')),
          SizedBox(width: 220, child: _HeaderCell('Nama Mata Kuliah')),
          SizedBox(width: 60, child: _HeaderCell('SKS', center: true)),
          SizedBox(width: 80, child: _HeaderCell('Semester', center: true)),
          SizedBox(width: 60, child: _HeaderCell('Prodi', center: true)),
          Expanded(child: _HeaderCell('Profesi Relevan')),
          SizedBox(width: 100, child: _HeaderCell('Prioritas', center: true)),
          SizedBox(width: 120, child: _HeaderCell('Aksi', center: true)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool center;
  const _HeaderCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _C.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Row tabel ────────────────────────────────────────────────────────────────
class _TableRow extends StatefulWidget {
  final MataKuliah mk;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const _TableRow({
    required this.mk,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final mk = widget.mk;
    final prio = mk.prioritas;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hover ? _C.primary.withOpacity(0.03) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Kode MK
            SizedBox(
              width: 100,
              child: Text(
                mk.mkId,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ),
            // Nama MK
            SizedBox(
              width: 220,
              child: Tooltip(
                message: mk.mkDeskripsi.isNotEmpty ? mk.mkDeskripsi : mk.mkNama,
                child: Text(
                  mk.mkNama,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // SKS
            SizedBox(
              width: 60,
              child: Text(
                '${mk.mkSks}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _C.textSecondary),
              ),
            ),
            // Semester
            SizedBox(
              width: 80,
              child: Text(
                '${mk.mkSemester}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _C.textSecondary),
              ),
            ),
            // Prodi
            SizedBox(
              width: 60,
              child: Text(
                mk.mkProdi,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _C.textSecondary),
              ),
            ),
            // Profesi badge
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    mk.profesiList.map((p) => _ProfesiBadge(label: p)).toList(),
              ),
            ),
            // Prioritas
            SizedBox(
              width: 100,
              child: Center(
                child: _PrioritasBadge(prioritas: prio),
              ),
            ),
            // Aksi
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Edit
                  TextButton(
                    onPressed: widget.onEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Edit',
                        style: TextStyle(
                            fontSize: 12,
                            color: _C.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  // Hapus
                  TextButton(
                    onPressed: widget.onHapus,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      backgroundColor: _C.dangerLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Hapus',
                        style: TextStyle(
                            fontSize: 12,
                            color: _C.danger,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge profesi ────────────────────────────────────────────────────────────
class _ProfesiBadge extends StatelessWidget {
  final String label;
  const _ProfesiBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = _badgeColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }

  (Color, Color) _badgeColor(String label) {
    final l = label.toLowerCase();
    if (l.contains('data') || l.contains('sci'))
      return (const Color(0xFFE3F2FD), const Color(0xFF1565C0));
    if (l.contains('soft') || l.contains('eng') || l.contains('dev'))
      return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
    if (l.contains('ai') || l.contains('ml'))
      return (const Color(0xFFF3E5F5), const Color(0xFF6A1B9A));
    if (l.contains('backend') || l.contains('db'))
      return (const Color(0xFFFFF8E1), const Color(0xFFE65100));
    if (l.contains('sys') || l.contains('analyst'))
      return (const Color(0xFFE0F2F1), const Color(0xFF00695C));
    return (const Color(0xFFF5F5F5), const Color(0xFF616161));
  }
}

// ─── Badge prioritas ──────────────────────────────────────────────────────────
class _PrioritasBadge extends StatelessWidget {
  final String prioritas;
  const _PrioritasBadge({required this.prioritas});

  @override
  Widget build(BuildContext context) {
    final color = _C.prioritasColor(prioritas);
    return Container(
      width: 36,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        prioritas,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ─── Row kosong ───────────────────────────────────────────────────────────────
class _EmptyRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: 48, color: _C.textMuted),
          const SizedBox(height: 12),
          const Text('Tidak ada mata kuliah',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.textSecondary)),
          const SizedBox(height: 4),
          const Text('Coba ubah filter atau tambah MK baru',
              style: TextStyle(fontSize: 12, color: _C.textMuted)),
        ],
      ),
    );
  }
}

// ─── Footer tabel ─────────────────────────────────────────────────────────────
class _TableFooter extends StatelessWidget {
  final int showing;
  final int total;
  final int page;
  final int perPage;

  const _TableFooter({
    required this.showing,
    required this.total,
    required this.page,
    required this.perPage,
  });

  @override
  Widget build(BuildContext context) {
    final start = page * perPage + 1;
    final end = (page * perPage + showing).clamp(0, total);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        'Menampilkan $start–$end dari $total mata kuliah',
        style: const TextStyle(fontSize: 12, color: _C.textMuted),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: _C.danger, size: 48),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.textSecondary)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: _C.primary),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

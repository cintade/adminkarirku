import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:adminkarieku/features/roadmap/data/roadmap_langkah_model.dart';
import 'package:adminkarieku/features/roadmap/data/roadmap_langkah_repository.dart';
import 'package:adminkarieku/features/roadmap/widgets/tambah_langkah_dialog.dart';
import 'package:adminkarieku/core/theme/app_theme.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final _repo = RoadmapLangkahRepository();

  String? _filterKarierId;
  KategoriLangkah? _filterKategori;
  String _search = '';
  List<String> _karirIds = [];

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKarirIds();
  }

  Future<void> _loadKarirIds() async {
    final ids = await _repo.getKarirIds();
    if (mounted) setState(() => _karirIds = ids);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          _buildFilterBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Roadmap Karir',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text('Kelola langkah roadmap yang tampil di aplikasi mahasiswa',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
          const Spacer(),
          // Info chip total langkah
          StreamBuilder<List<RoadmapLangkah>>(
            stream: _repo.streamSemua(),
            builder: (_, snap) {
              final total = snap.data?.length ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(children: [
                  Icon(Icons.route_rounded,
                      size: 14, color: Colors.indigo.shade600),
                  const SizedBox(width: 6),
                  Text('$total langkah total',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w600)),
                ]),
              );
            },
          ),
          ElevatedButton.icon(
            onPressed: _showTambahDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Langkah'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final hasFilter = _filterKategori != null ||
        _filterKarierId != null ||
        _search.isNotEmpty;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 260,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari deskripsi...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: Colors.grey.shade400),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        })
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: AppColors.sidebarAccent, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Filter Kategori
          _dropdown<KategoriLangkah?>(
            value: _filterKategori,
            hint: 'Semua Kategori',
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Semua Kategori')),
              ...KategoriLangkah.values
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.label))),
            ],
            onChanged: (v) => setState(() => _filterKategori = v),
          ),
          const SizedBox(width: 10),

          // Filter Karir — dinamis dari Firestore
          _dropdown<String?>(
            value: _filterKarierId,
            hint: 'Semua Karir',
            items: [
              const DropdownMenuItem(value: null, child: Text('Semua Karir')),
              ..._karirIds
                  .map((id) => DropdownMenuItem(value: id, child: Text(id))),
            ],
            onChanged: (v) => setState(() => _filterKarierId = v),
          ),

          const Spacer(),

          if (hasFilter)
            TextButton.icon(
              onPressed: () => setState(() {
                _filterKategori = null;
                _filterKarierId = null;
                _search = '';
                _searchCtrl.clear();
              }),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Reset'),
              style:
                  TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(hint,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            items: items,
            onChanged: onChanged,
            isDense: true,
          ),
        ),
      );

  Widget _buildContent() {
    return StreamBuilder<List<RoadmapLangkah>>(
      stream: _repo.streamSemua(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        var list = snap.data ?? [];

        // Apply filters
        if (_filterKategori != null) {
          list = list.where((l) => l.kategori == _filterKategori).toList();
        }
        if (_filterKarierId != null) {
          list = list.where((l) => l.karierId == _filterKarierId).toList();
        }
        if (_search.isNotEmpty) {
          list = list
              .where((l) =>
                  l.deskripsi.toLowerCase().contains(_search) ||
                  l.karierId.toLowerCase().contains(_search))
              .toList();
        }

        if (list.isEmpty) return _buildEmptyState();

        // Group by karierId untuk tampilan lebih rapi
        return _buildGroupedTable(list);
      },
    );
  }

  // ── Grouped by Karir ─────────────────────────────────────────────────────────
  Widget _buildGroupedTable(List<RoadmapLangkah> list) {
    // Kelompokkan per karir
    final Map<String, List<RoadmapLangkah>> grouped = {};
    for (final l in list) {
      grouped.putIfAbsent(l.karierId, () => []).add(l);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final karierId = grouped.keys.elementAt(i);
        final langkahList = grouped[karierId]!;
        return _buildKarirGroup(karierId, langkahList);
      },
    );
  }

  Widget _buildKarirGroup(String karierId, List<RoadmapLangkah> langkahList) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.work_outline_rounded,
                    size: 16, color: Colors.indigo.shade600),
                const SizedBox(width: 8),
                Text(
                  karierId,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade800),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${langkahList.length} langkah',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                // Tambah langkah untuk karir ini
                TextButton.icon(
                  onPressed: () => _showTambahDialog(karierId: karierId),
                  icon: Icon(Icons.add_rounded,
                      size: 14, color: Colors.indigo.shade600),
                  label: Text('Tambah',
                      style: TextStyle(
                          fontSize: 12, color: Colors.indigo.shade600)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4)),
                ),
              ],
            ),
          ),

          // Tabel langkah
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Table(
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: Colors.grey.shade100, width: 1),
              ),
              columnWidths: const {
                0: FixedColumnWidth(44), // No urut
                1: FlexColumnWidth(4), // Deskripsi
                2: FixedColumnWidth(110), // Kategori
                3: FixedColumnWidth(90), // Target Smt
                4: FixedColumnWidth(110), // Sumber Gap
                5: FixedColumnWidth(90), // Status
                6: FixedColumnWidth(80), // Aksi
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: [
                    _th('#'),
                    _th('Deskripsi Langkah'),
                    _th('Kategori'),
                    _th('Target Smt'),
                    _th('Sumber Gap'),
                    _th('Status'),
                    _th('Aksi'),
                  ],
                ),
                // Rows
                ...langkahList
                    .asMap()
                    .entries
                    .map((e) => _buildRow(e.key, e.value)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildRow(int idx, RoadmapLangkah l) => TableRow(
        decoration: BoxDecoration(
          color: idx.isEven ? Colors.white : const Color(0xFFFAFAFA),
        ),
        children: [
          _td(l.urutan.toString(), center: true),
          _tdDeskripsi(l.deskripsi),
          _tdKategori(l.kategori),
          _tdSmt(l.targetSmt),
          _tdChip(l.sumberGap, Colors.orange),
          _tdStatus(l.status),
          _tdAksi(l),
        ],
      );

  // ── Cell widgets ─────────────────────────────────────────────────────────────
  Widget _th(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
      );

  Widget _td(String t, {bool center = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(t,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
      );

  Widget _tdDeskripsi(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(t,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      );

  Widget _tdKategori(KategoriLangkah k) {
    final color = _kategoriColor(k);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(k.label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _tdSmt(int smt) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Center(
                child: Text('$smt',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade700)),
              ),
            ),
            const SizedBox(width: 5),
            Text('Smt',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      );

  Widget _tdChip(String text, MaterialColor color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(text.isEmpty ? '—' : text,
              style: TextStyle(
                  fontSize: 11,
                  color: color.shade800,
                  fontWeight: FontWeight.w500)),
        ),
      );

  Widget _tdStatus(StatusLangkah s) {
    final data = {
      StatusLangkah.belum: (
        Colors.grey.shade100,
        Colors.grey.shade600,
        'Belum'
      ),
      StatusLangkah.sedang: (
        Colors.blue.shade50,
        Colors.blue.shade700,
        'Sedang'
      ),
      StatusLangkah.selesai: (
        Colors.green.shade50,
        Colors.green.shade700,
        'Selesai'
      ),
    };
    final (bg, fg, label) = data[s]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _tdAksi(RoadmapLangkah l) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showEditDialog(l),
              icon: const Icon(Icons.edit_outlined, size: 15),
              color: Colors.blue,
              tooltip: 'Edit',
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              onPressed: () => _hapus(l),
              icon: const Icon(Icons.delete_outline_rounded, size: 15),
              color: Colors.red,
              tooltip: 'Hapus',
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
            Icon(Icons.route_rounded, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada langkah roadmap',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Klik "+ Tambah Langkah" untuk mulai mengisi data',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showTambahDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Tambah Langkah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sidebarAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

  // ── Helpers ──────────────────────────────────────────────────────────────────
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

  void _showTambahDialog({String? karierId}) => showDialog(
        context: context,
        builder: (_) => TambahLangkahDialog(defaultKarierId: karierId),
      ).then((_) => _loadKarirIds());

  void _showEditDialog(RoadmapLangkah l) => showDialog(
        context: context,
        builder: (_) => TambahLangkahDialog(langkahEdit: l),
      ).then((_) => _loadKarirIds());

  Future<void> _hapus(RoadmapLangkah l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Langkah'),
        content: Text(
            'Yakin hapus langkah "${l.deskripsi}"?\n\nData ini akan hilang dari roadmap mahasiswa.'),
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
    if (ok == true && l.docId != null) {
      await _repo.hapus(l.docId!);
      if (mounted) _loadKarirIds();
    }
  }
}

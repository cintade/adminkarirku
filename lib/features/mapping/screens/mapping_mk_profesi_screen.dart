import 'package:flutter/material.dart';
import '../models/mata_kuliah_model.dart';
import '../models/karir_model.dart';
import '../services/admin_mapping_service.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/priority_badge.dart';
import '../widgets/mapping_form_dialog.dart';

/// Halaman admin "Mapping MK — Profesi".
///
/// PENTING — disesuaikan dengan struktur data ASLI: relasi Karir <-> MK
/// disimpan sebagai array `mk_pendukung` (nama mata kuliah) di dalam
/// dokumen karir itu sendiri, BUKAN tabel relasi terpisah. Urutan di
/// dalam array = prioritas (item pertama paling relevan). Karena itu:
///
/// - Panel kanan "Dari Profesi" adalah tempat utama mengelola urutan
///   (naik/turun = ubah prioritas, hapus = keluarkan dari array).
/// - Panel kiri "Dari Mata Kuliah" bersifat pencarian terbalik (lihat
///   karir mana saja yang menyebut MK ini) — tombol "Kelola" akan
///   memindahkan fokus ke panel kanan untuk karir tersebut.
class MappingMkProfesiScreen extends StatefulWidget {
  const MappingMkProfesiScreen({super.key});

  @override
  State<MappingMkProfesiScreen> createState() => _MappingMkProfesiScreenState();
}

class _MappingMkProfesiScreenState extends State<MappingMkProfesiScreen> {
  final _service = AdminMappingService();

  List<MataKuliah> _allMk = [];
  List<Karir> _allKarir = [];

  String? _selectedMkNama;
  String? _selectedKarirId;

  List<MapEntry<Karir, int>> _karirByMk = [];
  List<MapEntry<MataKuliah?, int>> _mkByKarir = [];

  bool _loadingReference = true;
  bool _loadingLeft = false;
  bool _loadingRight = false;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    setState(() => _loadingReference = true);
    final mkList = await _service.getAllMataKuliah();
    final karirList = await _service.getAllKarir();
    setState(() {
      _allMk = mkList;
      _allKarir = karirList;
      _selectedMkNama ??= mkList.isNotEmpty ? mkList.first.mkNama : null;
      _selectedKarirId ??=
          karirList.isNotEmpty ? karirList.first.karirId : null;
      _loadingReference = false;
    });
    await Future.wait([_loadLeftPanel(), _loadRightPanel()]);
  }

  Karir? get _selectedKarir =>
      _allKarir.where((k) => k.karirId == _selectedKarirId).firstOrNull;

  Future<void> _loadLeftPanel() async {
    if (_selectedMkNama == null) return;
    setState(() => _loadingLeft = true);
    final result = await _service.getKarirByMkNama(_selectedMkNama!);
    setState(() {
      _karirByMk = result;
      _loadingLeft = false;
    });
  }

  Future<void> _loadRightPanel() async {
    final karir = _selectedKarir;
    if (karir == null) return;
    setState(() => _loadingRight = true);
    final result = await _service.getMkPendukungDetail(karir);
    setState(() {
      _mkByKarir = result;
      _loadingRight = false;
    });
  }

  Future<void> _refreshAll() async {
    // Karir bisa berubah (mk_pendukung-nya), jadi reload daftar karir juga.
    final karirList = await _service.getAllKarir();
    setState(() => _allKarir = karirList);
    await Future.wait([_loadLeftPanel(), _loadRightPanel()]);
  }

  void _openAddDialog({String? fixedMkNama, String? fixedKarirId}) {
    showDialog(
      context: context,
      builder: (_) => MappingFormDialog(
        allMataKuliah: _allMk,
        allKarir: _allKarir,
        fixedMkNama: fixedMkNama,
        fixedKarirId: fixedKarirId,
        onSaved: _refreshAll,
      ),
    );
  }

  Future<void> _moveItem(Karir karir, int index, int delta) async {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= karir.mkPendukung.length) return;
    final newOrder = List<String>.from(karir.mkPendukung);
    final item = newOrder.removeAt(index);
    newOrder.insert(newIndex, item);
    await _service.setMkPendukungOrder(karir.karirId, newOrder);
    await _refreshAll();
  }

  Future<void> _removeItem(Karir karir, String mkNama) async {
    await _service.removeMkPendukung(karir.karirId, mkNama);
    await _refreshAll();
  }

  void _kelolaDariKiri(String karirId) {
    setState(() => _selectedKarirId = karirId);
    _loadRightPanel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: const AdminTopBar(),
      body: _loadingReference
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      final left = _buildLeftPanel();
                      final right = _buildRightPanel();
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
                        children: [left, const SizedBox(height: 20), right],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        const Text('Mapping MK — Profesi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Fitur import belum diimplementasikan')),
            );
          },
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Import'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _openAddDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B2559),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah Mapping'),
        ),
      ],
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  // ---------------- Panel kiri: Dari Mata Kuliah ----------------
  Widget _buildLeftPanel() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dari Mata Kuliah',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedMkNama,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F7FB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            items: _allMk
                .map((mk) =>
                    DropdownMenuItem(value: mk.mkNama, child: Text(mk.label)))
                .toList(),
            onChanged: (v) {
              setState(() => _selectedMkNama = v);
              _loadLeftPanel();
            },
          ),
          const SizedBox(height: 16),
          if (_loadingLeft)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_karirByMk.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada karir yang terhubung dengan MK ini',
                  style: TextStyle(color: Colors.grey[600])),
            )
          else
            ..._karirByMk.map((entry) {
              final karir = entry.key;
              final priority = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEDEDF3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(karir.nama,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      PriorityBadge(priority: priority),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => _kelolaDariKiri(karir.karirId),
                        child: const Text('Kelola'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _selectedMkNama == null
                  ? null
                  : () => _openAddDialog(fixedMkNama: _selectedMkNama),
              child: const Text('+ Tambah Profesi'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Panel kanan: Dari Profesi ----------------
  Widget _buildRightPanel() {
    final karir = _selectedKarir;
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dari Profesi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedKarirId,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F7FB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            items: _allKarir
                .map((k) =>
                    DropdownMenuItem(value: k.karirId, child: Text(k.nama)))
                .toList(),
            onChanged: (v) {
              setState(() => _selectedKarirId = v);
              _loadRightPanel();
            },
          ),
          const SizedBox(height: 16),
          if (_loadingRight)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_mkByKarir.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                  'Belum ada mata kuliah yang terhubung dengan karir ini',
                  style: TextStyle(color: Colors.grey[600])),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _tableHeaderCell('Mata Kuliah')),
                    SizedBox(width: 90, child: _tableHeaderCell('Semester')),
                    SizedBox(width: 70, child: _tableHeaderCell('Prioritas')),
                    SizedBox(width: 140, child: _tableHeaderCell('Aksi')),
                  ],
                ),
                ...List.generate(_mkByKarir.length, (index) {
                  final mk = _mkByKarir[index].key;
                  final priority = _mkByKarir[index].value;
                  final namaTampil = mk?.mkNama ?? karir!.mkPendukung[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(namaTampil,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        SizedBox(
                            width: 90, child: Text('${mk?.mkSemester ?? '-'}')),
                        SizedBox(
                            width: 70,
                            child: PriorityBadge(priority: priority)),
                        SizedBox(
                          width: 140,
                          child: Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                tooltip: 'Naikkan prioritas',
                                icon: const Icon(Icons.arrow_upward, size: 16),
                                onPressed: index == 0
                                    ? null
                                    : () => _moveItem(karir!, index, -1),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                tooltip: 'Turunkan prioritas',
                                icon:
                                    const Icon(Icons.arrow_downward, size: 16),
                                onPressed: index == _mkByKarir.length - 1
                                    ? null
                                    : () => _moveItem(karir!, index, 1),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                tooltip: 'Hapus',
                                icon: const Icon(Icons.delete_outline,
                                    size: 16, color: Colors.red),
                                onPressed: () => _removeItem(
                                    karir!, karir.mkPendukung[index]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _selectedKarirId == null
                  ? null
                  : () => _openAddDialog(fixedKarirId: _selectedKarirId),
              child: const Text('+ Tambah Mata Kuliah'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child:
          Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

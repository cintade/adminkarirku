import 'package:adminkarieku/features/aturan_rekomendasi_karir/presentation/aturan_rekomendasi_list_screen.dart';
import 'package:adminkarieku/features/mapping/screens/mapping_mk_profesi_screen.dart';
import 'package:adminkarieku/features/mata_kuliah/presentation/mata_kuliah_page.dart';
import 'package:flutter/material.dart';
import '../../shared/widgets/admin_sidebar.dart';
import 'package:adminkarieku/features/manajemen_tes/presentation/manajemen_tes_screen.dart';
import 'package:adminkarieku/features/dashboard/dashboard_page.dart';
import 'package:adminkarieku/features/karir/presentation/data_karir_screen.dart';
import 'package:adminkarieku/features/roadmap/presentation/roadmap_screen.dart';
import 'package:adminkarieku/features/laporan/laporan_screen.dart';
import 'package:adminkarieku/features/mahasiswa/presentation/mahasiswa_list_screen.dart';
import 'package:adminkarieku/features/pengaturan/presentation/pengaturan_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _activeIndex = 0; // ← ganti ke 0 (Dashboard aktif pertama)

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage(); // ← TAMBAH
      case 1:
        return const MahasiswaListScreen();
      case 2:
        return const ManajemenTesScreen();
      case 3: // ← sesuaikan index sidebar Data Karir
        return const DataKarirScreen();
      case 4: // sesuaikan index sidebar Mata Kuliah
        return const MataKuliahPage();
      case 5:
        return const MappingMkProfesiScreen();
      case 6:
        return const RoadmapScreen();
      case 7:
        return const AturanRekomendasiListScreen();
      case 8:
        return const LaporanScreen();
      case 9:
        return const PengaturanPage();
      default:
        return _PlaceholderPage(index: index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            activeIndex: _activeIndex,
            onItemTap: (i) => setState(() => _activeIndex = i),
          ),
          Expanded(child: _getPage(_activeIndex)),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final int index;
  const _PlaceholderPage({required this.index});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Halaman index $index belum tersedia',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isActive;
  final VoidCallback? onTap;

  const SidebarItem({
    required this.icon,
    required this.label,
    this.badge,
    this.isActive = false,
    this.onTap,
  });
}

class AdminSidebar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int>? onItemTap;

  const AdminSidebar({
    super.key,
    this.activeIndex = 2,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: 8),
                  // Nav groups
                  _buildSectionLabel('UTAMA'),
                  _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                  _buildNavItemMahasiswa(1),
                  _buildNavItem(2, Icons.assignment_outlined, 'Manajemen Tes'),
                  _buildNavItem(3, Icons.work_outline_rounded, 'Data Karier'),
                  const SizedBox(height: 8),
                  _buildSectionLabel('AKADEMIK'),
                  _buildNavItem(4, Icons.menu_book_outlined, 'Mata Kuliah'),
                  _buildNavItem(5, Icons.account_tree_outlined, 'Mapping MK'),
                  _buildNavItem(6, Icons.map_outlined, 'Roadmap'),
                  const SizedBox(height: 8),
                  _buildSectionLabel('SISTEM'),
                  _buildNavItem(7, Icons.rule_folder_outlined,
                      'Aturan Rekomendasi Karir'),
                  _buildNavItem(8, Icons.bar_chart_rounded, 'Laporan'),
                  _buildNavItem(9, Icons.settings_outlined, 'Pengaturan'),
                ],
              ),
            ),
          ),
          _buildAdminProfile(),
        ],
      ),
    );
  }

  /// Item "Mahasiswa" khusus, badge-nya diambil realtime dari jumlah
  /// dokumen di collection `users` (bukan angka statis lagi).
  ///
  /// Catatan: idealnya pakai aggregate count query (`count().snapshots()`)
  /// supaya tidak perlu download semua dokumen, tapi itu butuh versi
  /// cloud_firestore yang lebih baru. Untuk skala ~250 mahasiswa,
  /// `.snapshots()` + `.docs.length` biasa ini masih cukup ringan dan
  /// kompatibel dengan versi yang lebih lama.
  Widget _buildNavItemMahasiswa(int index) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final jumlah = snapshot.data?.docs.length;
        return _buildNavItem(
          index,
          Icons.person_outline_rounded,
          'Mahasiswa',
          badge: jumlah == null ? '...' : '$jumlah',
        );
      },
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                heightFactor: 0.6,
                widthFactor: 0.6,
                child: Image.asset(
                  'assets/images/logo1.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PathWise',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Admin Panel',
                style: TextStyle(
                  color: AppColors.sidebarText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      {String? badge}) {
    final isActive = activeIndex == index;
    return InkWell(
      onTap: () => onItemTap?.call(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border(
                  left: BorderSide(color: AppColors.sidebarAccent, width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : AppColors.sidebarText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.sidebarText,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfile() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.sidebarActive,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.sidebarAccent,
            child: Text('A',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text('Super Admin',
                    style:
                        TextStyle(color: AppColors.sidebarText, fontSize: 10)),
              ],
            ),
          ),
          // Tombol logout
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // AuthWrapper otomatis redirect ke LoginScreen
            },
            icon: const Icon(Icons.logout,
                color: AppColors.sidebarText, size: 18),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}

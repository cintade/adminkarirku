import 'package:flutter/material.dart';
import 'package:adminkarieku/features/manajemen_tes/data/tab_disc.dart';
import 'package:adminkarieku/features/manajemen_tes/data/tab_riasec_likert.dart';
import 'package:adminkarieku/features/manajemen_tes/data/tab_riasec_paired.dart';
import 'package:adminkarieku/features/manajemen_tes/data/tab_sternberg.dart';

class ManajemenTesScreen extends StatefulWidget {
  const ManajemenTesScreen({super.key});

  @override
  State<ManajemenTesScreen> createState() => _ManajemenTesScreenState();
}

class _ManajemenTesScreenState extends State<ManajemenTesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _TabMeta(
      label: 'RIASEC Paired',
      icon: Icons.compare_arrows_rounded,
      color: Color(0xFF2563EB),
      subtitle: 'Perbandingan Berpasangan',
    ),
    _TabMeta(
      label: 'RIASEC Likert',
      icon: Icons.linear_scale_rounded,
      color: Color(0xFF9333EA),
      subtitle: 'Skala 1–5',
    ),
    _TabMeta(
      label: 'Sternberg',
      icon: Icons.psychology_rounded,
      color: Color(0xFFD97706),
      subtitle: 'Pilihan Ganda',
    ),
    _TabMeta(
      label: 'DISC',
      icon: Icons.grid_4x4_rounded,
      color: Color(0xFFDC2626),
      subtitle: 'Most & Least',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ───────────────────────────────────────────────────────
          _buildTopBar(),

          // ── Tab bar ───────────────────────────────────────────────────────
          _buildTabBar(),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12), top: Radius.circular(0)),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    TabRiasecPaired(),
                    TabRiasecLikert(),
                    TabSternberg(),
                    TabDisc(),
                  ],
                ),
              ),
            ),
          ),
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
              const Text(
                'Manajemen Tes',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              const SizedBox(height: 2),
              Text(
                'Kelola soal untuk semua jenis tes karier mahasiswa',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
          const Spacer(),
          // Info chip tab aktif
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey(_tabController.index),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _tabs[_tabController.index].color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _tabs[_tabController.index].color.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_tabs[_tabController.index].icon,
                      size: 16, color: _tabs[_tabController.index].color),
                  const SizedBox(width: 6),
                  Text(
                    '${_tabs[_tabController.index].label} · ${_tabs[_tabController.index].subtitle}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _tabs[_tabController.index].color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicatorPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          color: _tabs[_tabController.index].color.withOpacity(0.08),
          border: Border(
            bottom: BorderSide(
              color: _tabs[_tabController.index].color,
              width: 2.5,
            ),
          ),
        ),
        labelPadding: EdgeInsets.zero,
        tabs: List.generate(_tabs.length, (i) {
          final isActive = _tabController.index == i;
          final meta = _tabs[i];
          return Tab(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  meta.icon,
                  size: 16,
                  color: isActive ? meta.color : Colors.grey.shade400,
                ),
                const SizedBox(width: 7),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive ? meta.color : Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      meta.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive
                            ? meta.color.withOpacity(0.7)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TabMeta {
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _TabMeta({
    required this.label,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}

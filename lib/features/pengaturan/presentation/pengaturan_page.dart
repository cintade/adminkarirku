import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _C {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3F2FD);
  static const pageBg = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE8ECF0);
  static const divider = Color(0xFFF0F2F5);
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF6B7A8D);
  static const danger = Color(0xFFC62828);
  static const dangerLight = Color(0xFFFFEBEE);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const amber = Color(0xFFEF6C00);
  static const amberLight = Color(0xFFFFF3E0);
  static const purple = Color(0xFF6A1B9A);
  static const purpleLight = Color(0xFFF3E5F5);
}

const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _formatTanggal(DateTime? d) {
  if (d == null) return '-';
  final jam = d.hour.toString().padLeft(2, '0');
  final menit = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_bulan[d.month - 1]} ${d.year}, $jam:$menit';
}

String _sapaan() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 19) return 'Selamat sore';
  return 'Selamat malam';
}

class PengaturanPage extends StatelessWidget {
  const PengaturanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      color: _C.pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengaturan',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary)),
            const SizedBox(height: 2),
            const Text('Informasi akun dan aplikasi.',
                style: TextStyle(fontSize: 13, color: _C.textSecondary)),
            const SizedBox(height: 16),
            _kartuSambutan(user),
            const SizedBox(height: 16),
            _kartuRingkasanSistem(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _kartu(
                    title: 'Akun',
                    icon: Icons.person_outline_rounded,
                    iconColor: _C.primary,
                    iconBg: _C.primaryLight,
                    rows: [
                      _InfoRow('Email', user?.email ?? '-'),
                      _InfoRow('UID', user?.uid ?? '-', monospace: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _kartu(
                    title: 'Aktivitas Login',
                    icon: Icons.history_rounded,
                    iconColor: _C.amber,
                    iconBg: _C.amberLight,
                    rows: [
                      _InfoRow('Login Terakhir',
                          _formatTanggal(user?.metadata.lastSignInTime)),
                      _InfoRow('Akun Dibuat',
                          _formatTanggal(user?.metadata.creationTime)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _kartu(
                    title: 'Tentang Aplikasi',
                    icon: Icons.info_outline_rounded,
                    iconColor: _C.purple,
                    iconBg: _C.purpleLight,
                    rows: const [
                      _InfoRow('Nama Aplikasi', 'PathWise Admin Panel'),
                      _InfoRow('Versi', '1.0.0'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: 260, child: _tombolLogout(context)),
          ],
        ),
      ),
    );
  }

  // ── Kartu sambutan dengan gradient ──
  Widget _kartuSambutan(User? user) {
    final nama = user?.email?.split('@').first ?? 'Admin';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Icon(Icons.diamond_outlined,
                size: 130, color: Colors.white.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_sapaan()}, $nama 👋',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Semua sistem berjalan normal. Berikut ringkasan akun dan aplikasi kamu.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DotHidup(),
                    SizedBox(width: 6),
                    Text('Terhubung ke Firebase',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Kartu ringkasan sistem, live dari Firestore ──
  Widget _kartuRingkasanSistem() {
    return Row(
      children: [
        Expanded(
          child: _statLive(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            label: 'Total Mahasiswa',
            icon: Icons.groups_rounded,
            color: _C.primary,
            bg: _C.primaryLight,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statLive(
            stream: FirebaseFirestore.instance.collection('karir').snapshots(),
            label: 'Total Karier',
            icon: Icons.work_outline_rounded,
            color: _C.success,
            bg: _C.successLight,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statLive(
            stream: FirebaseFirestore.instance
                .collection('mata_kuliah')
                .snapshots(),
            label: 'Total Mata Kuliah',
            icon: Icons.menu_book_rounded,
            color: _C.purple,
            bg: _C.purpleLight,
          ),
        ),
      ],
    );
  }

  Widget _statLive({
    required Stream<QuerySnapshot> stream,
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        final jumlah = snap.data?.docs.length;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jumlah == null ? '...' : '$jumlah',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _C.textPrimary),
                    ),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11.5, color: _C.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tombolLogout(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _konfirmasiLogout(context),
        style: FilledButton.styleFrom(
          backgroundColor: _C.dangerLight,
          foregroundColor: _C.danger,
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  void _konfirmasiLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Anda akan keluar dari panel admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Batal', style: TextStyle(color: _C.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _C.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _kartu({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<_InfoRow> rows,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _C.textPrimary)),
            ]),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _C.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      rows[i].label,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12.5, color: _C.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _C.textPrimary,
                        fontFamily: rows[i].monospace ? 'monospace' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

// ── Titik hijau berkedip pelan, penanda "hidup"/online ──
class _DotHidup extends StatefulWidget {
  const _DotHidup();
  @override
  State<_DotHidup> createState() => _DotHidupState();
}

class _DotHidupState extends State<_DotHidup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_ctrl),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF4CD964),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _BarisIkon extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BarisIkon({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _C.textSecondary),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary)),
      ],
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool monospace;
  const _InfoRow(this.label, this.value, {this.monospace = false});
}

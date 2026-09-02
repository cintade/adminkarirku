import 'package:flutter/material.dart';

String _bulanTahunIndonesia(DateTime date) {
  const bulan = [
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
  return '${bulan[date.month - 1]} ${date.year}';
}

/// Top bar admin: judul halaman, kotak pencarian, ikon notifikasi,
/// dan label bulan/tahun — sesuai desain UI "Mapping MK".
class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final bulanTahun = _bulanTahunIndonesia(DateTime.now());

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9E9F0))),
      ),
      child: Row(
        children: [
          const Text(
            'Mapping MK',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // TODO: hubungkan ke fungsi pencarian global (mahasiswa, karier, dll)
          // kalau admin panel kamu punya modul lain di luar fitur mapping ini.
          SizedBox(
            width: 260,
            height: 38,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari mahasiswa, karier...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFF5F5FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(bulanTahun,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}

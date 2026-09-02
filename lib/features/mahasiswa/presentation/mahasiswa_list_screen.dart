import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:adminkarieku/features/mahasiswa/data/mahasiswa_model.dart';
import 'package:adminkarieku/features/mahasiswa/data/mahasiswa_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


const int _kBaris = 5; // jumlah baris per halaman, samakan dg screenshot

class MahasiswaListScreen extends StatefulWidget {
  const MahasiswaListScreen({super.key});

  @override
  State<MahasiswaListScreen> createState() => _MahasiswaListScreenState();
}

class _MahasiswaListScreenState extends State<MahasiswaListScreen> {
  final MahasiswaService _service = MahasiswaService();

  String _keyword = '';
  String _filterProdi = 'Semua Prodi';
  String _filterSemester = 'Semua Semester';
  String _filterStatus = 'Status Tes';
  int _halaman = 0;

  final Set<String> _terpilih = {};
  final Map<String, Future<RingkasanTes>> _cacheRingkasan = {};

  Future<RingkasanTes> _ringkasanTes(String uid) {
    // Cache supaya tidak fetch ulang tiap kali ListView rebuild (scroll,
    // ganti filter, dll) — cukup 1x per uid selama widget ini hidup.
    return _cacheRingkasan.putIfAbsent(uid, () => _service.ambilRingkasanTes(uid));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MahasiswaModel>>(
      stream: _service.streamMahasiswa(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final semua = snapshot.data!;
        final hasil = _terapkanFilter(semua);
        final totalHalaman = (hasil.length / _kBaris).ceil().clamp(1, 999999);
        if (_halaman >= totalHalaman) _halaman = 0;
        final awal = _halaman * _kBaris;
        final akhir = (awal + _kBaris).clamp(0, hasil.length);
        final halamanIni = hasil.sublist(awal, akhir);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(semua.length, hasil),
              const SizedBox(height: 20),
              _buildFilterBar(semua),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(halamanIni, semua),
                      Expanded(
                        child: halamanIni.isEmpty
                            ? const Center(child: Text('Tidak ada data mahasiswa'))
                            : ListView.separated(
                                itemCount: halamanIni.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1, color: Colors.grey.shade200),
                                itemBuilder: (context, i) =>
                                    _buildRow(halamanIni[i]),
                              ),
                      ),
                      _buildFooter(hasil.length, awal, akhir, totalHalaman),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // FILTER + SEARCH (dilakukan di client agar tidak perlu composite index)
  // ---------------------------------------------------------------------
  List<MahasiswaModel> _terapkanFilter(List<MahasiswaModel> data) {
    return data.where((m) {
      final cocokKeyword = _keyword.isEmpty ||
          m.nama.toLowerCase().contains(_keyword.toLowerCase()) ||
          m.email.toLowerCase().contains(_keyword.toLowerCase());
      final cocokProdi = _filterProdi == 'Semua Prodi' || m.prodi == _filterProdi;
      final cocokSemester = _filterSemester == 'Semua Semester' ||
          m.semester.toString() == _filterSemester;
      final cocokStatus = _filterStatus == 'Status Tes' || m.statusTes == _filterStatus;
      return cocokKeyword && cocokProdi && cocokSemester && cocokStatus;
    }).toList();
  }

  // ---------------------------------------------------------------------
  // HEADER: judul + tombol Tambah & Ekspor CSV
  // ---------------------------------------------------------------------
  Widget _buildHeader(int totalSemua, List<MahasiswaModel> hasilFilter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Manajemen Mahasiswa',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _exportCsv(hasilFilter),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Ekspor CSV'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _tampilkanDialogTambah,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // FILTER BAR: search + 3 dropdown
  // ---------------------------------------------------------------------
  Widget _buildFilterBar(List<MahasiswaModel> semua) {
    final daftarProdi = <String>{'Semua Prodi', ...semua.map((e) => e.prodi)}.toList();
    final daftarSemester = <String>{
      'Semua Semester',
      ...semua.map((e) => e.semester.toString())
    }.toList();
    const daftarStatus = ['Status Tes', 'Lengkap', 'Sebagian', 'Belum'];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari nama / email...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => setState(() {
              _keyword = v;
              _halaman = 0;
            }),
          ),
        ),
        const SizedBox(width: 12),
        _dropdown(_filterProdi, daftarProdi, (v) => setState(() {
              _filterProdi = v!;
              _halaman = 0;
            })),
        const SizedBox(width: 12),
        _dropdown(_filterSemester, daftarSemester, (v) => setState(() {
              _filterSemester = v!;
              _halaman = 0;
            })),
        const SizedBox(width: 12),
        _dropdown(_filterStatus, daftarStatus, (v) => setState(() {
              _filterStatus = v!;
              _halaman = 0;
            })),
      ],
    );
  }

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TABLE HEADER
  // ---------------------------------------------------------------------
  Widget _buildTableHeader(List<MahasiswaModel> halamanIni, List<MahasiswaModel> semua) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: const [
          SizedBox(width: 32),
          Expanded(flex: 3, child: Text('Mahasiswa', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Prodi', style: _headerStyle)),
          Expanded(child: Text('Semester', style: _headerStyle)),
          Expanded(child: Text('RIASEC', style: _headerStyle)),
          Expanded(child: Text('Tes', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Kesiapan', style: _headerStyle)),
          Expanded(child: Text('Roadmap', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Aksi', style: _headerStyle)),
        ],
      ),
    );
  }

  static const _headerStyle =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey);

  // ---------------------------------------------------------------------
  // ROW
  // ---------------------------------------------------------------------
  Widget _buildRow(MahasiswaModel m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: _terpilih.contains(m.id),
              onChanged: (v) => setState(() {
                v == true ? _terpilih.add(m.id) : _terpilih.remove(m.id);
              }),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(m.inisial,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nama,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(m.email,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(m.prodi)),
          Expanded(child: Text('${m.semester}')),
          Expanded(
            flex: 4,
            child: FutureBuilder<RingkasanTes>(
              future: _ringkasanTes(m.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Row(
                    children: [
                      Expanded(child: SizedBox()),
                      Expanded(child: SizedBox()),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ],
                  );
                }
                final r = snapshot.data!;
                return Row(
                  children: [
                    Expanded(child: _chipRiasec(r.riasecDominant)),
                    Expanded(child: _badgeStatus(r.statusTes)),
                    Expanded(flex: 2, child: _kesiapanBar(r.kesiapanPercentage)),
                  ],
                );
              },
            ),
          ),
          Expanded(child: Text('${m.roadmapAktifCount} aktif')),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                TextButton(
                  onPressed: () => _bukaDetail(m),
                  child: const Text('Detail'),
                ),
                TextButton(
                  onPressed: () => _konfirmasiHapus(m),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipRiasec(String kode) {
    if (kode == '-') return const Text('-');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(kode,
          style: TextStyle(
              color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _badgeStatus(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Lengkap':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'Sebagian':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _kesiapanBar(double? persen) {
    if (persen == null) {
      return Text('—', style: TextStyle(color: Colors.grey.shade400));
    }
    return Row(
      children: [
        Text('${persen.toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: persen / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF2563EB),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // FOOTER: info jumlah + pagination
  // ---------------------------------------------------------------------
  Widget _buildFooter(int total, int awal, int akhir, int totalHalaman) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            total == 0
                ? 'Tidak ada data'
                : 'Menampilkan ${awal + 1}-$akhir dari $total mahasiswa',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: _halaman > 0 ? () => setState(() => _halaman--) : null,
              ),
              for (int i = 0; i < totalHalaman && i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => setState(() => _halaman = i),
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == _halaman ? const Color(0xFF2563EB) : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i == _halaman ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed:
                    _halaman < totalHalaman - 1 ? () => setState(() => _halaman++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // AKSI: detail, hapus, tambah, export
  // ---------------------------------------------------------------------
  void _bukaDetail(MahasiswaModel m) {
    // TODO: arahkan ke halaman detail mahasiswa (hasil tes lengkap, roadmap, dsb)
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('Detail ${m.nama}')),
        body: Center(child: Text('Halaman detail untuk ${m.nama} (${m.email})')),
      ),
    ));
  }

  Future<void> _konfirmasiHapus(MahasiswaModel m) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Mahasiswa'),
        content: Text('Yakin ingin menghapus data ${m.nama}? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin == true) {
      await _service.hapusMahasiswa(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Data ${m.nama} dihapus')));
      }
    }
  }

  void _tampilkanDialogTambah() {
    final namaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final prodiCtrl = TextEditingController();
    final semesterCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Mahasiswa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: prodiCtrl, decoration: const InputDecoration(labelText: 'Prodi')),
              TextField(
                controller: semesterCtrl,
                decoration: const InputDecoration(labelText: 'Semester'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final mhs = MahasiswaModel(
                id: '',
                nama: namaCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                prodi: prodiCtrl.text.trim(),
                semester: int.tryParse(semesterCtrl.text.trim()) ?? 0,
                riasecDominant: '-',
                statusTes: 'Belum',
                kesiapanPercentage: null,
                roadmapAktifCount: 0,
                createdAt: DateTime.now(),
              );
              await _service.tambahMahasiswa(mhs);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Ekspor data yang sedang tampil (sesuai filter aktif) ke file CSV.
  /// Menggunakan dart:html sehingga hanya berjalan di Flutter Web.
  void _exportCsv(List<MahasiswaModel> data) {
    final buffer = StringBuffer();
    buffer.writeln('Nama,Email,Prodi,Semester,RIASEC,Status Tes,Kesiapan (%),Roadmap Aktif');
    for (final m in data) {
      buffer.writeln(
          '"${m.nama}","${m.email}","${m.prodi}",${m.semester},"${m.riasecDominant}","${m.statusTes}",${m.kesiapanPercentage?.toStringAsFixed(0) ?? ''},${m.roadmapAktifCount}');
    }
    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'data_mahasiswa.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
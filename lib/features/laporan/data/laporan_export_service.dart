import 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import '../data/laporan_model.dart';

// ══════════════════════════════════════════════════════════════
// LAPORAN EXPORT SERVICE
//
// Mengekspor data laporan ke file Excel (.xlsx) ATAU PDF (.pdf)
// yang bisa langsung diunduh dari browser (Flutter Web).
//
// Dependency yang perlu ditambahkan ke pubspec.yaml:
//   excel: ^4.0.6
//   pdf: ^3.11.1   # cek versi terbaru di pub.dev/packages/pdf
//
// Cara pakai:
//   await LaporanExportService.eksporExcel(context, data);
//   await LaporanExportService.eksporPdf(context, data);
// ══════════════════════════════════════════════════════════════
class LaporanExportService {
  LaporanExportService._();

  // ════════════════════════════════════════════════════════════
  // EKSPOR EXCEL
  // ════════════════════════════════════════════════════════════

  /// Ekspor seluruh data laporan ke file Excel dengan 3 sheet:
  /// 1. Overview        — 4 statistik utama
  /// 2. Analisis Tes    — sebaran RIASEC, DISC, Bakat
  /// 3. Sebaran Karir   — tabel karir yang paling direkomendasikan
  static Future<void> eksporExcel(
    BuildContext context,
    LaporanData data,
  ) async {
    try {
      final excel = Excel.createExcel();

      // Hapus sheet default kosong
      excel.delete('Sheet1');

      _buatSheetOverview(excel, data);
      _buatSheetAnalisaTes(excel, data);
      _buatSheetSebaranKarir(excel, data);

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Gagal menghasilkan file Excel');

      _unduhFile(
        bytes: Uint8List.fromList(bytes),
        namaFile: 'laporan_karirku_${_formatTanggal(data.dimuatPada)}.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      _tampilkanSukses(context, 'File Excel berhasil diunduh');
    } catch (e) {
      _tampilkanGagal(context, 'Gagal ekspor Excel: $e');
    }
  }

  // ── Sheet 1: Overview ──────────────────────────────────────
  static void _buatSheetOverview(Excel excel, LaporanData data) {
    final sheet = excel['Overview'];
    final ov = data.overview;

    // Judul
    _setCell(sheet, 0, 0, 'LAPORAN & ANALITIK — KarirKu',
        bold: true, fontSize: 14);
    _setCell(
        sheet, 1, 0, 'Diekspor pada: ${_formatTanggalPanjang(data.dimuatPada)}',
        color: '64748B');
    _setRow(sheet, 3, ['Metrik', 'Nilai', 'Keterangan'],
        bold: true, bgColor: '1E3A5F', fgColor: 'FFFFFF');

    _setRow(sheet, 4, [
      'Tingkat Penyelesaian Tes',
      '${ov.tingkatPenyelesaianTes.toStringAsFixed(1)}%',
      'Mahasiswa yang selesai ketiga tes (RIASEC, DISC, Bakat)',
    ]);
    _setRow(sheet, 5, [
      'Mahasiswa Aktif',
      '${ov.mahasiswaAktif}',
      '${ov.persenMahasiswaAktif.toStringAsFixed(1)}% dari total ${ov.totalMahasiswa} mahasiswa',
    ]);
    _setRow(sheet, 6, [
      'Roadmap Selesai',
      '${ov.roadmapSelesai}',
      '${ov.persenRoadmapSelesai.toStringAsFixed(1)}% dari total roadmap',
    ]);
    _setRow(sheet, 7, [
      'Waktu Rata-rata Tes',
      '${ov.waktuRataRataTes.toStringAsFixed(0)} menit',
      'Per sesi pengerjaan tes',
    ]);
    _setRow(sheet, 8, [
      'Total Mahasiswa Terdaftar',
      '${ov.totalMahasiswa}',
      '',
    ]);

    // Kesiapan per semester
    _setCell(sheet, 10, 0, 'Kesiapan per Semester', bold: true);
    _setRow(sheet, 11, ['Semester', '% Kesiapan Akademik'],
        bold: true, bgColor: '2563EB', fgColor: 'FFFFFF');
    for (var i = 0; i < data.kesiapanPerSemester.length; i++) {
      final item = data.kesiapanPerSemester[i];
      _setRow(sheet, 12 + i, [item.label, item.persenKesiapan]);
    }

    // Sebaran jenjang
    final offsetJenjang = 12 + data.kesiapanPerSemester.length + 2;
    _setCell(sheet, offsetJenjang, 0, 'Sebaran Jenjang', bold: true);
    _setRow(sheet, offsetJenjang + 1,
        ['Jenjang', 'Jumlah Mahasiswa', 'Persentase (%)'],
        bold: true, bgColor: '2563EB', fgColor: 'FFFFFF');
    for (var i = 0; i < data.sebaranJenjang.length; i++) {
      final j = data.sebaranJenjang[i];
      _setRow(
          sheet, offsetJenjang + 2 + i, [j.jenjang, j.jumlah, j.persentase]);
    }

    _lebarKolom(sheet, [35, 20, 60]);
  }

  // ── Sheet 2: Analisis Tes ──────────────────────────────────
  static void _buatSheetAnalisaTes(Excel excel, LaporanData data) {
    final sheet = excel['Analisis Tes'];
    final a = data.analisisTes;

    _setCell(sheet, 0, 0, 'ANALISIS TES', bold: true, fontSize: 13);

    // RIASEC
    _setCell(sheet, 2, 0, 'Sebaran Tipe Dominan RIASEC', bold: true);
    _setRow(sheet, 3, ['Tipe', 'Jumlah Mahasiswa'],
        bold: true, bgColor: '2563EB', fgColor: 'FFFFFF');
    var row = 4;
    a.sebaranRiasec.forEach((tipe, jumlah) {
      _setRow(sheet, row++, [tipe, jumlah]);
    });

    // DISC
    row += 1;
    _setCell(sheet, row, 0, 'Sebaran Tipe Dominan DISC', bold: true);
    _setRow(sheet, ++row, ['Tipe', 'Jumlah Mahasiswa'],
        bold: true, bgColor: '16A34A', fgColor: 'FFFFFF');
    row++;
    a.sebaranDisc.forEach((tipe, jumlah) {
      _setRow(sheet, row++, [tipe, jumlah]);
    });

    // Bakat
    row += 1;
    _setCell(sheet, row, 0, 'Sebaran Kategori Bakat (Sternberg)', bold: true);
    _setRow(sheet, ++row, ['Kategori', 'Jumlah Mahasiswa'],
        bold: true, bgColor: '7C3AED', fgColor: 'FFFFFF');
    row++;
    a.sebaranBakat.forEach((kat, jumlah) {
      _setRow(sheet, row++, [kat, jumlah]);
    });

    // Rata-rata skor RIASEC
    row += 1;
    _setCell(sheet, row, 0, 'Rata-rata Skor RIASEC per Dimensi', bold: true);
    _setRow(sheet, ++row, ['Dimensi', 'Rata-rata Skor (mentah)'],
        bold: true, bgColor: 'F59E0B', fgColor: 'FFFFFF');
    row++;
    a.rataRataSkorRiasec.forEach((dim, skor) {
      _setRow(sheet, row++, [dim, double.parse(skor.toStringAsFixed(2))]);
    });

    _lebarKolom(sheet, [35, 25]);
  }

  // ── Sheet 3: Sebaran Karir ─────────────────────────────────
  static void _buatSheetSebaranKarir(Excel excel, LaporanData data) {
    final sheet = excel['Sebaran Karir'];

    _setCell(sheet, 0, 0, 'SEBARAN REKOMENDASI KARIR',
        bold: true, fontSize: 13);
    _setCell(sheet, 1, 0,
        'Karir diurutkan berdasarkan frekuensi kemunculan di rekomendasi',
        color: '64748B');

    _setRow(
      sheet,
      3,
      [
        'No',
        'Karir',
        'Direkomendasikan (mahasiswa)',
        'Rata-rata Skor Akhir (%)',
        'Rata-rata Kesiapan Akademik (%)',
      ],
      bold: true,
      bgColor: '1E3A5F',
      fgColor: 'FFFFFF',
    );

    for (var i = 0; i < data.sebaranKarir.length; i++) {
      final k = data.sebaranKarir[i];
      final bgColor = i.isEven ? 'FFFFFF' : 'F8FAFC';
      _setRow(
        sheet,
        4 + i,
        [
          i + 1,
          '${k.emoji} ${k.namaKarir}',
          k.jumlahDirekomendasikan,
          k.rataRataSkorAkhir,
          k.rataRataKesiapanAkademik,
        ],
        bgColor: bgColor,
      );
    }

    _lebarKolom(sheet, [6, 35, 28, 24, 28]);
  }

  // ── Helper Excel: isi 1 sel ────────────────────────────────
  // fontColorHex & backgroundColorHex di CellStyle bertipe
  // non-nullable (ExcelColor), bukan ExcelColor?. Default resmi
  // package: fontColorHex = ExcelColor.black,
  //          backgroundColorHex = ExcelColor.none.
  static void _setCell(
    Sheet sheet,
    int row,
    int col,
    dynamic value, {
    bool bold = false,
    int fontSize = 11,
    String? color,
    String? bgColor,
  }) {
    final cellIndex =
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);
    final cell = sheet.cell(cellIndex);
    cell.value = _toExcelValue(value);
    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize,
      fontColorHex: color != null
          ? ExcelColor.fromHexString('#$color')
          : ExcelColor.black,
      backgroundColorHex: bgColor != null
          ? ExcelColor.fromHexString('#$bgColor')
          : ExcelColor.none,
    );
  }

  // ── Helper Excel: isi 1 baris ──────────────────────────────
  static void _setRow(
    Sheet sheet,
    int row,
    List<dynamic> values, {
    bool bold = false,
    String? bgColor,
    String? fgColor,
  }) {
    for (var col = 0; col < values.length; col++) {
      final cellIndex =
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);
      final cell = sheet.cell(cellIndex);
      cell.value = _toExcelValue(values[col]);
      cell.cellStyle = CellStyle(
        bold: bold,
        backgroundColorHex: bgColor != null
            ? ExcelColor.fromHexString('#$bgColor')
            : ExcelColor.none,
        fontColorHex: fgColor != null
            ? ExcelColor.fromHexString('#$fgColor')
            : ExcelColor.black,
      );
    }
  }

  // ── Helper Excel: lebar kolom ──────────────────────────────
  static void _lebarKolom(Sheet sheet, List<int> lebarList) {
    for (var i = 0; i < lebarList.length; i++) {
      sheet.setColumnWidth(i, lebarList[i].toDouble());
    }
  }

  // ── Helper Excel: konversi ke CellValue ────────────────────
  static CellValue? _toExcelValue(dynamic v) {
    if (v == null) return null;
    if (v is int) return IntCellValue(v);
    if (v is double) return DoubleCellValue(v);
    if (v is bool) return BoolCellValue(v);
    return TextCellValue(v.toString());
  }

  // ════════════════════════════════════════════════════════════
  // EKSPOR PDF
  // ════════════════════════════════════════════════════════════

  /// Ekspor seluruh data laporan ke file PDF dengan 3 halaman/section:
  /// 1. Overview        — ringkasan, kesiapan per semester, sebaran jenjang
  /// 2. Analisis Tes    — sebaran RIASEC, DISC, Bakat
  /// 3. Sebaran Karir   — tabel karir yang paling direkomendasikan
  ///
  /// Memakai pw.MultiPage supaya tabel panjang (mis. daftar karir/mahasiswa
  /// banyak) otomatis lanjut ke halaman berikutnya, bukan terpotong.
  static Future<void> eksporPdf(
    BuildContext context,
    LaporanData data,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(_buatHalamanOverviewPdf(data));
      pdf.addPage(_buatHalamanAnalisisTesPdf(data));
      pdf.addPage(_buatHalamanSebaranKarirPdf(data));

      final bytes = await pdf.save();

      _unduhFile(
        bytes: bytes,
        namaFile: 'laporan_karirku_${_formatTanggal(data.dimuatPada)}.pdf',
        mimeType: 'application/pdf',
      );

      _tampilkanSukses(context, 'File PDF berhasil diunduh');
    } catch (e) {
      _tampilkanGagal(context, 'Gagal ekspor PDF: $e');
    }
  }

  // Style dipakai berulang di semua halaman PDF.
  static final pw.TextStyle _judulSeksi = pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blueGrey900,
  );
  static final pw.TextStyle _headerTabel = pw.TextStyle(
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  );
  static const pw.TextStyle _selTabel = pw.TextStyle(fontSize: 9);

  // ── Halaman 1: Overview ────────────────────────────────────
  static pw.MultiPage _buatHalamanOverviewPdf(LaporanData data) {
    final ov = data.overview;
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) =>
          _headerPdf('Laporan & Analitik — KarirKu', data.dimuatPada),
      footer: (context) => _footerPdf(context),
      build: (context) => [
        pw.Text('Ringkasan', style: _judulSeksi),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          context: context,
          headers: const ['Metrik', 'Nilai', 'Keterangan'],
          data: [
            [
              'Tingkat Penyelesaian Tes',
              '${ov.tingkatPenyelesaianTes.toStringAsFixed(1)}%',
              'Mahasiswa yang selesai ketiga tes (RIASEC, DISC, Bakat)',
            ],
            [
              'Mahasiswa Aktif',
              '${ov.mahasiswaAktif}',
              '${ov.persenMahasiswaAktif.toStringAsFixed(1)}% dari total ${ov.totalMahasiswa} mahasiswa',
            ],
            [
              'Roadmap Selesai',
              '${ov.roadmapSelesai}',
              '${ov.persenRoadmapSelesai.toStringAsFixed(1)}% dari total roadmap',
            ],
            [
              'Waktu Rata-rata Tes',
              '${ov.waktuRataRataTes.toStringAsFixed(0)} menit',
              'Per sesi pengerjaan tes',
            ],
            ['Total Mahasiswa Terdaftar', '${ov.totalMahasiswa}', ''],
          ],
          headerStyle: _headerTabel,
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A5F)),
          cellStyle: _selTabel,
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(5),
          },
        ),
        pw.SizedBox(height: 18),
        pw.Text('Kesiapan per Semester', style: _judulSeksi),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          context: context,
          headers: const ['Semester', '% Kesiapan Akademik'],
          data: data.kesiapanPerSemester
              .map((e) => [e.label, _fmt(e.persenKesiapan)])
              .toList(),
          headerStyle: _headerTabel,
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
          cellStyle: _selTabel,
        ),
        pw.SizedBox(height: 18),
        pw.Text('Sebaran Jenjang', style: _judulSeksi),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          context: context,
          headers: const ['Jenjang', 'Jumlah Mahasiswa', 'Persentase (%)'],
          data: data.sebaranJenjang
              .map((j) => [j.jenjang, '${j.jumlah}', _fmt(j.persentase)])
              .toList(),
          headerStyle: _headerTabel,
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
          cellStyle: _selTabel,
        ),
      ],
    );
  }

  // ── Halaman 2: Analisis Tes ────────────────────────────────
  static pw.MultiPage _buatHalamanAnalisisTesPdf(LaporanData data) {
    final a = data.analisisTes;
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => _headerPdf('Analisis Tes', data.dimuatPada),
      footer: (context) => _footerPdf(context),
      build: (context) => [
        pw.Text('Sebaran Tipe Dominan RIASEC', style: _judulSeksi),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          context: context,
          headers: const ['Tipe', 'Jumlah Mahasiswa'],
          data: a.sebaranRiasec.entries
              .map((e) => [e.key, '${e.value}'])
              .toList(),
          headerStyle: _headerTabel,
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
          cellStyle: _selTabel,
        ),
        pw.SizedBox(height: 16),
        pw.Text('Sebaran Tipe Dominan DISC', style: _judulSeksi),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          context: context,
          headers: const ['Tipe', 'Jumlah Mahasiswa'],
          data:
              a.sebaranDisc.entries.map((e) => [e.key, '${e.value}']).toList(),
          headerStyle: _headerTabel,
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF16A34A)),
          cellStyle: _selTabel,
        ),
        pw.SizedBox(height: 16),
        pw.Text('Sebaran Kategori Bakat (Sternberg)', style: _judulSeksi),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          context: context,
          headers: const ['Kategori', 'Jumlah Mahasiswa'],
          data:
              a.sebaranBakat.entries.map((e) => [e.key, '${e.value}']).toList(),
          headerStyle: _headerTabel,
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7C3AED)),
          cellStyle: _selTabel,
        ),
        pw.SizedBox(height: 16),
        pw.Text('Rata-rata Skor RIASEC per Dimensi', style: _judulSeksi),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          context: context,
          headers: const ['Dimensi', 'Rata-rata Skor (mentah)'],
          data: a.rataRataSkorRiasec.entries
              .map((e) => [e.key, e.value.toStringAsFixed(2)])
              .toList(),
          headerStyle: _headerTabel,
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF59E0B)),
          cellStyle: _selTabel,
        ),
      ],
    );
  }

  // ── Halaman 3: Sebaran Karir ───────────────────────────────
  // Catatan: font default PDF (Helvetica) tidak mendukung glyph emoji,
  // sehingga emoji sengaja TIDAK disertakan di versi PDF (beda dari versi
  // Excel) supaya tidak muncul kotak putus-putus (tofu) di dokumen.
  static pw.MultiPage _buatHalamanSebaranKarirPdf(LaporanData data) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) =>
          _headerPdf('Sebaran Rekomendasi Karir', data.dimuatPada),
      footer: (context) => _footerPdf(context),
      build: (context) => [
        pw.Text(
          'Karir diurutkan berdasarkan frekuensi kemunculan di rekomendasi',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
          context: context,
          headers: const [
            'No',
            'Karir',
            'Direkomendasikan',
            'Skor Akhir (%)',
            'Kesiapan Akademik (%)',
          ],
          data: List.generate(data.sebaranKarir.length, (i) {
            final k = data.sebaranKarir[i];
            return [
              '${i + 1}',
              k.namaKarir,
              '${k.jumlahDirekomendasikan}',
              _fmt(k.rataRataSkorAkhir),
              _fmt(k.rataRataKesiapanAkademik),
            ];
          }),
          headerStyle: _headerTabel,
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A5F)),
          cellStyle: _selTabel,
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(4),
            2: pw.FlexColumnWidth(3),
            3: pw.FlexColumnWidth(2.5),
            4: pw.FlexColumnWidth(3),
          },
        ),
      ],
    );
  }

  // ── Helper PDF: header berulang tiap halaman ───────────────
  static pw.Widget _headerPdf(String judul, DateTime dimuatPada) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(judul,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(
          'Diekspor pada: ${_formatTanggalPanjang(dimuatPada)}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(height: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 8),
      ],
    );
  }

  // ── Helper PDF: footer nomor halaman ───────────────────────
  static pw.Widget _footerPdf(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(height: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Text(
          'Halaman ${context.pageNumber} dari ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ── Helper PDF: format angka aman untuk tabel (int/double/lainnya) ─
  static String _fmt(dynamic v) {
    if (v is double) return v.toStringAsFixed(1);
    return v.toString();
  }

  // ════════════════════════════════════════════════════════════
  // HELPER BERSAMA (dipakai Excel & PDF)
  // ════════════════════════════════════════════════════════════

  // ── Helper: unduh file di browser ─────────────────────────
  static void _unduhFile({
    required Uint8List bytes,
    required String namaFile,
    required String mimeType,
  }) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', namaFile)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static void _tampilkanSukses(BuildContext context, String pesan) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $pesan'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  static void _tampilkanGagal(BuildContext context, String pesan) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $pesan'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ── Helper: format tanggal ─────────────────────────────────
  static String _formatTanggal(DateTime dt) =>
      '${dt.year}${_pad(dt.month)}${_pad(dt.day)}';

  static String _formatTanggalPanjang(DateTime dt) =>
      '${_pad(dt.day)}/${_pad(dt.month)}/${dt.year} '
      '${_pad(dt.hour)}:${_pad(dt.minute)}';

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

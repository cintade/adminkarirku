import 'dart:typed_data';
import 'package:excel/excel.dart' as xl;
import 'mata_kuliah_model.dart';

// ─── Hasil parsing 1 baris Excel ───────────────────────────────────────────
class MkImportRow {
  final int rowNumber; // nomor baris di Excel (termasuk header)
  final MataKuliah? mk; // null jika baris gagal divalidasi
  final String? error;

  MkImportRow({required this.rowNumber, this.mk, this.error});

  bool get isValid => mk != null && error == null;
}

// ─── Service parsing & generate template Excel MK ──────────────────────────
class MataKuliahExcelService {
  // Alias header yang dikenali (case-insensitive)
  static const Map<String, List<String>> _headerAliases = {
    'mk_id': ['mk_id', 'kode', 'kode mk', 'kode_mk'],
    'mk_nama': ['mk_nama', 'nama', 'nama mk', 'nama mata kuliah'],
    'mk_sks': ['mk_sks', 'sks'],
    'mk_semester': ['mk_semester', 'semester'],
    'mk_prodi': ['mk_prodi', 'prodi'],
    'tipe': ['tipe', 'jenis'],
    'mk_segment1': [
      'mk_segment1',
      'segment1',
      'segment 1',
      'profesi 1',
      'profesi1'
    ],
    'mk_segment2': [
      'mk_segment2',
      'segment2',
      'segment 2',
      'profesi 2',
      'profesi2'
    ],
    'mk_segment3': [
      'mk_segment3',
      'segment3',
      'segment 3',
      'profesi 3',
      'profesi3'
    ],
    'mk_deskripsi': ['mk_deskripsi', 'deskripsi'],
  };

  static const validTipe = [
    'Wajib',
    'Pilihan Utama',
    'Pilihan',
    'Penunjang',
    'Lainnya'
  ];

  static const requiredColumns = ['mk_id', 'mk_nama', 'mk_prodi'];

  /// Parse bytes .xlsx menjadi list baris hasil (valid & invalid).
  /// [existingIds] = kumpulan mk_id yang sudah ada di database (huruf besar)
  /// untuk deteksi duplikat terhadap data existing.
  static List<MkImportRow> parse(
    Uint8List bytes, {
    Set<String> existingIds = const {},
  }) {
    late final xl.Excel excel;
    try {
      excel = xl.Excel.decodeBytes(bytes);
    } catch (_) {
      throw Exception(
          'File tidak bisa dibaca. Pastikan file berformat .xlsx yang valid.');
    }

    if (excel.tables.isEmpty) {
      throw Exception('File Excel tidak memiliki sheet.');
    }

    // Ambil sheet pertama yang punya isi
    final sheet = excel.tables.values.firstWhere(
      (t) => t.maxRows > 0,
      orElse: () => excel.tables.values.first,
    );

    if (sheet.maxRows < 2) {
      throw Exception(
          'Sheet tidak memiliki data (hanya header atau kosong).');
    }

    // ── Baca header ──────────────────────────────────────────────────────
    final headerRow = sheet.rows.first;
    final Map<String, int> colIndex = {};
    for (int c = 0; c < headerRow.length; c++) {
      final raw = headerRow[c]?.value?.toString().trim().toLowerCase() ?? '';
      if (raw.isEmpty) continue;
      for (final entry in _headerAliases.entries) {
        if (entry.value.contains(raw) && !colIndex.containsKey(entry.key)) {
          colIndex[entry.key] = c;
        }
      }
    }

    final missing =
        requiredColumns.where((f) => !colIndex.containsKey(f)).toList();
    if (missing.isNotEmpty) {
      throw Exception(
          'Kolom wajib tidak ditemukan: ${missing.join(", ")}.\nGunakan template resmi agar nama kolom sesuai.');
    }

    final List<MkImportRow> results = [];
    final seenIdsInFile = <String>{};

    for (int r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      final excelRowNumber = r + 1; // 1-based, termasuk header

      String cell(String field) {
        final idx = colIndex[field];
        if (idx == null || idx >= row.length) return '';
        final v = row[idx]?.value;
        if (v == null) return '';
        final s = v.toString().trim();
        return s == 'null' ? '' : s;
      }

      final mkId = cell('mk_id');
      final mkNama = cell('mk_nama');
      final mkProdi = cell('mk_prodi');

      // Baris kosong sepenuhnya → lewati diam-diam
      if (mkId.isEmpty && mkNama.isEmpty && mkProdi.isEmpty) continue;

      if (mkId.isEmpty || mkNama.isEmpty || mkProdi.isEmpty) {
        results.add(MkImportRow(
          rowNumber: excelRowNumber,
          error: 'Kolom mk_id, mk_nama, dan mk_prodi wajib diisi',
        ));
        continue;
      }

      final idUpper = mkId.toUpperCase();

      if (seenIdsInFile.contains(idUpper)) {
        results.add(MkImportRow(
          rowNumber: excelRowNumber,
          error: 'Kode MK "$mkId" duplikat di dalam file ini',
        ));
        continue;
      }

      if (existingIds.contains(idUpper)) {
        results.add(MkImportRow(
          rowNumber: excelRowNumber,
          error: 'Kode MK "$mkId" sudah terdaftar di database',
        ));
        continue;
      }

      final sksStr = cell('mk_sks');
      final semesterStr = cell('mk_semester');
      final sks = int.tryParse(sksStr) ?? -1;
      final semester = int.tryParse(semesterStr) ?? -1;

      if (sksStr.isNotEmpty && sks <= 0) {
        results.add(MkImportRow(
          rowNumber: excelRowNumber,
          error: 'SKS harus angka positif (nilai: "$sksStr")',
        ));
        continue;
      }
      if (semesterStr.isNotEmpty && (semester < 1 || semester > 8)) {
        results.add(MkImportRow(
          rowNumber: excelRowNumber,
          error: 'Semester harus 1-8 (nilai: "$semesterStr")',
        ));
        continue;
      }

      var tipe = cell('tipe');
      if (tipe.isEmpty) {
        tipe = 'Wajib';
      } else {
        final match = validTipe.firstWhere(
          (t) => t.toLowerCase() == tipe.toLowerCase(),
          orElse: () => '',
        );
        if (match.isEmpty) {
          results.add(MkImportRow(
            rowNumber: excelRowNumber,
            error:
                'Tipe "$tipe" tidak dikenali. Gunakan: ${validTipe.join(", ")}',
          ));
          continue;
        }
        tipe = match;
      }

      seenIdsInFile.add(idUpper);

      results.add(MkImportRow(
        rowNumber: excelRowNumber,
        mk: MataKuliah(
          mkId: idUpper,
          mkNama: mkNama,
          mkSks: sks > 0 ? sks : 3,
          mkSemester: semester > 0 ? semester : 1,
          mkSegment1: cell('mk_segment1'),
          mkSegment2: cell('mk_segment2'),
          mkSegment3: cell('mk_segment3'),
          mkDeskripsi: cell('mk_deskripsi'),
          mkProdi: mkProdi.toUpperCase(),
          tipe: tipe,
        ),
      ));
    }

    return results;
  }

  /// Buat file template .xlsx kosong dengan header + 1 baris contoh
  static Uint8List generateTemplate() {
    final excel = xl.Excel.createExcel();
    const sheetName = 'Mata Kuliah';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    const headers = [
      'mk_id',
      'mk_nama',
      'mk_sks',
      'mk_semester',
      'mk_prodi',
      'tipe',
      'mk_segment1',
      'mk_segment2',
      'mk_segment3',
      'mk_deskripsi',
    ];
    sheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());

    sheet.appendRow([
      xl.TextCellValue('IF301'),
      xl.TextCellValue('Pemrograman Web'),
      xl.IntCellValue(3),
      xl.IntCellValue(5),
      xl.TextCellValue('TI'),
      xl.TextCellValue('Wajib'),
      xl.TextCellValue('Web Developer'),
      xl.TextCellValue('Software Engineer'),
      xl.TextCellValue(''),
      xl.TextCellValue('Mata kuliah pengantar pengembangan aplikasi web'),
    ]);

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 22);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Gagal membuat file template');
    }
    return Uint8List.fromList(bytes);
  }
}
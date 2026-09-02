import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'mata_kuliah_model.dart';
import 'mata_kuliah_excel_service.dart';
import 'mata_kuliah_repository.dart';

// ─── Warna (sesuai app_theme admin) ──────────────────────────────────────────
class _C {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3F2FD);
  static const pageBg = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE8ECF0);
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF6B7A8D);
  static const textMuted = Color(0xFF9AA5B4);
  static const danger = Color(0xFFC62828);
  static const dangerLight = Color(0xFFFFEBEE);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFE65100);
}

/// Dialog import Mata Kuliah dari Excel.
/// Return value: jumlah MK yang berhasil diimport (int), atau null jika batal.
class ImportExcelMkDialog extends StatefulWidget {
  final Set<String> existingMkIds; // untuk deteksi duplikat vs database

  const ImportExcelMkDialog({super.key, required this.existingMkIds});

  @override
  State<ImportExcelMkDialog> createState() => _ImportExcelMkDialogState();
}

class _ImportExcelMkDialogState extends State<ImportExcelMkDialog> {
  final _repo = MataKuliahRepository();

  String? _fileName;
  List<MkImportRow> _rows = [];
  String? _parseError;
  bool _isParsing = false;
  bool _isImporting = false;

  List<MkImportRow> get _validRows => _rows.where((r) => r.isValid).toList();
  List<MkImportRow> get _invalidRows => _rows.where((r) => !r.isValid).toList();

  // ── Pilih & parse file ───────────────────────────────────────────────────
  Future<void> _pilihFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      setState(() => _parseError = 'Gagal membaca isi file');
      return;
    }

    setState(() {
      _isParsing = true;
      _parseError = null;
      _rows = [];
      _fileName = file.name;
    });

    try {
      final parsed = MataKuliahExcelService.parse(
        file.bytes!,
        existingIds: widget.existingMkIds,
      );
      setState(() => _rows = parsed);
    } catch (e) {
      setState(
          () => _parseError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isParsing = false);
    }
  }

  // ── Download template ────────────────────────────────────────────────────
  Future<void> _downloadTemplate() async {
    try {
      final Uint8List bytes = MataKuliahExcelService.generateTemplate();
      await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Template MK',
        fileName: 'template_mata_kuliah.xlsx',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat template: $e')),
      );
    }
  }

  // ── Proses import ke Firestore ───────────────────────────────────────────
  Future<void> _import() async {
    final valid = _validRows.map((r) => r.mk!).toList();
    if (valid.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final sukses = await _repo.importBatch(valid);
      if (!mounted) return;
      Navigator.pop(context, sukses);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal import: $e'),
          backgroundColor: _C.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 720,
        height: 640,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: _C.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructions(),
                    const SizedBox(height: 20),
                    _buildPickArea(),
                    if (_parseError != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBox(_parseError!),
                    ],
                    if (_rows.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSummary(),
                      const SizedBox(height: 12),
                      _buildPreviewTable(),
                    ],
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.upload_file_rounded,
                color: _C.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Import Mata Kuliah dari Excel',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _isImporting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: _C.pageBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Instruksi + tombol template ───────────────────────────────────────────
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: _C.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Format kolom yang dibutuhkan',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'mk_id, mk_nama, mk_sks, mk_semester, mk_prodi, tipe, '
                  'mk_segment1, mk_segment2, mk_segment3, mk_deskripsi.\n'
                  'Kolom mk_id, mk_nama, dan mk_prodi wajib diisi.',
                  style: TextStyle(fontSize: 12, color: _C.textSecondary),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _downloadTemplate,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.download_rounded,
                      size: 16, color: _C.primary),
                  label: const Text('Download Template Excel',
                      style: TextStyle(
                          fontSize: 12,
                          color: _C.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Area pilih file ────────────────────────────────────────────────────
  Widget _buildPickArea() {
    return InkWell(
      onTap: _isParsing ? null : _pilihFile,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: _C.pageBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _fileName != null ? _C.primary : _C.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            if (_isParsing)
              const CircularProgressIndicator(color: _C.primary)
            else
              Icon(
                _fileName != null
                    ? Icons.description_rounded
                    : Icons.cloud_upload_outlined,
                size: 32,
                color: _fileName != null ? _C.primary : _C.textMuted,
              ),
            const SizedBox(height: 8),
            Text(
              _isParsing
                  ? 'Membaca file...'
                  : (_fileName ?? 'Klik untuk pilih file .xlsx'),
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    _fileName != null ? FontWeight.w600 : FontWeight.w500,
                color: _fileName != null ? _C.textPrimary : _C.textSecondary,
              ),
            ),
            if (_fileName == null) ...[
              const SizedBox(height: 4),
              const Text(
                'Hanya file .xlsx yang didukung',
                style: TextStyle(fontSize: 11, color: _C.textMuted),
              ),
            ] else if (!_isParsing) ...[
              const SizedBox(height: 4),
              const Text(
                'Klik untuk pilih file lain',
                style: TextStyle(fontSize: 11, color: _C.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Error box ──────────────────────────────────────────────────────────
  Widget _buildErrorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.dangerLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.danger.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _C.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(fontSize: 12.5, color: _C.danger)),
          ),
        ],
      ),
    );
  }

  // ─── Ringkasan hasil parsing ────────────────────────────────────────────
  Widget _buildSummary() {
    return Row(
      children: [
        _summaryChip(
          icon: Icons.check_circle_rounded,
          color: _C.success,
          label: '${_validRows.length} valid',
        ),
        const SizedBox(width: 8),
        if (_invalidRows.isNotEmpty)
          _summaryChip(
            icon: Icons.cancel_rounded,
            color: _C.danger,
            label: '${_invalidRows.length} bermasalah',
          ),
      ],
    );
  }

  Widget _summaryChip(
      {required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─── Tabel preview ──────────────────────────────────────────────────────
  Widget _buildPreviewTable() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: _C.pageBg,
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            child: const Row(
              children: [
                SizedBox(
                    width: 40,
                    child: Text('Baris',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.textMuted))),
                SizedBox(width: 8),
                SizedBox(
                    width: 70,
                    child: Text('Kode',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.textMuted))),
                Expanded(
                    flex: 2,
                    child: Text('Nama MK',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.textMuted))),
                Expanded(
                    flex: 3,
                    child: Text('Status',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.textMuted))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _C.border),
              itemBuilder: (_, i) {
                final row = _rows[i];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text('${row.rowNumber}',
                            style: const TextStyle(
                                fontSize: 12, color: _C.textMuted)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          row.mk?.mkId ?? '—',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _C.textPrimary),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          row.mk?.mkNama ?? '—',
                          style: const TextStyle(
                              fontSize: 12, color: _C.textPrimary),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              row.isValid
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              size: 14,
                              color: row.isValid ? _C.success : _C.danger,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                row.isValid ? 'Siap diimport' : row.error!,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color:
                                        row.isValid ? _C.success : _C.danger),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final validCount = _validRows.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isImporting ? null : () => Navigator.pop(context),
            child:
                const Text('Batal', style: TextStyle(color: _C.textSecondary)),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _C.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: (validCount == 0 || _isImporting) ? null : _import,
            icon: _isImporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.upload_file_rounded, size: 16),
            label: Text(
              _isImporting
                  ? 'Mengimport...'
                  : (validCount > 0 ? 'Import $validCount MK' : 'Import'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

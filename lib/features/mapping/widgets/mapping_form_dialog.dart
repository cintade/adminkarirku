import 'package:flutter/material.dart';
import '../models/mata_kuliah_model.dart';
import '../models/karir_model.dart';
import '../services/admin_mapping_service.dart';

/// Dialog untuk MENAMBAHKAN satu mata kuliah ke field `mk_pendukung`
/// milik satu karir. Karena relasinya berupa array (bukan tabel
/// terpisah dengan ID sendiri), dialog ini hanya untuk "tambah" —
/// edit prioritas (urutan) dan hapus dilakukan langsung lewat
/// tombol naik/turun/hapus di list pada halaman utama.
///
/// - [fixedMkNama]: kunci dropdown Mata Kuliah ke nilai ini (dipakai
///   dari panel kiri "+ Tambah Profesi").
/// - [fixedKarirId]: kunci dropdown Karir ke nilai ini (dipakai dari
///   panel kanan "+ Tambah MK").
class MappingFormDialog extends StatefulWidget {
  final List<MataKuliah> allMataKuliah;
  final List<Karir> allKarir;
  final String? fixedMkNama;
  final String? fixedKarirId;
  final VoidCallback onSaved;

  const MappingFormDialog({
    super.key,
    required this.allMataKuliah,
    required this.allKarir,
    required this.onSaved,
    this.fixedMkNama,
    this.fixedKarirId,
  });

  @override
  State<MappingFormDialog> createState() => _MappingFormDialogState();
}

class _MappingFormDialogState extends State<MappingFormDialog> {
  final _service = AdminMappingService();
  final _formKey = GlobalKey<FormState>();

  String? _mkNama;
  String? _karirId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mkNama = widget.fixedMkNama;
    _karirId = widget.fixedKarirId;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.addMkPendukung(_karirId!, _mkNama!);
      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan mapping: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tambah Mapping',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Mata kuliah akan ditambahkan ke akhir daftar pendukung karir '
                  '(prioritas terendah). Atur urutan/prioritas lewat tombol naik/turun setelah ditambahkan.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _mkNama,
                  decoration: const InputDecoration(labelText: 'Mata Kuliah'),
                  items: widget.allMataKuliah
                      .map((mk) => DropdownMenuItem(
                          value: mk.mkNama, child: Text(mk.label)))
                      .toList(),
                  onChanged: widget.fixedMkNama != null
                      ? null
                      : (v) => setState(() => _mkNama = v),
                  validator: (v) => v == null ? 'Pilih mata kuliah' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _karirId,
                  decoration:
                      const InputDecoration(labelText: 'Karir / Profesi'),
                  items: widget.allKarir
                      .map((k) => DropdownMenuItem(
                          value: k.karirId, child: Text(k.nama)))
                      .toList(),
                  onChanged: widget.fixedKarirId != null
                      ? null
                      : (v) => setState(() => _karirId = v),
                  validator: (v) => v == null ? 'Pilih karir' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B2559),
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

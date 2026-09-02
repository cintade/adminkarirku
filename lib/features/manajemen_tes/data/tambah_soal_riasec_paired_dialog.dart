import 'package:flutter/material.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_riasec_model.dart';
import 'package:adminkarieku/features/manajemen_tes/data/repositories/soal_riasec_repository.dart';

class TambahSoalRiasecPairedDialog extends StatefulWidget {
  final SoalRiasec? soalEdit;
  const TambahSoalRiasecPairedDialog({super.key, this.soalEdit});

  @override
  State<TambahSoalRiasecPairedDialog> createState() =>
      _TambahSoalRiasecPairedDialogState();
}

class _TambahSoalRiasecPairedDialogState
    extends State<TambahSoalRiasecPairedDialog> {
  final _repo = SoalRiasecRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _pernyataanACtrl;
  late final TextEditingController _pernyataanBCtrl;
  String _tipeA = 'R';
  String _tipeB = 'I';
  bool _loading = false;

  static const _tipeOptions = ['R', 'I', 'A', 'S', 'E', 'C'];

  @override
  void initState() {
    super.initState();
    final s = widget.soalEdit;
    _pernyataanACtrl = TextEditingController(text: s?.pernyataanA ?? '');
    _pernyataanBCtrl = TextEditingController(text: s?.pernyataanB ?? '');
    _tipeA = s?.tipeA ?? 'R';
    _tipeB = s?.tipeB ?? 'I';
  }

  @override
  void dispose() {
    _pernyataanACtrl.dispose();
    _pernyataanBCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.soalEdit != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Soal Paired' : 'Tambah Soal Paired'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPernyataanRow('A', _pernyataanACtrl, _tipeA, (v) {
                setState(() => _tipeA = v!);
              }),
              const SizedBox(height: 16),
              _buildPernyataanRow('B', _pernyataanBCtrl, _tipeB, (v) {
                setState(() => _tipeB = v!);
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _loading ? null : _simpan,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }

  Widget _buildPernyataanRow(String label, TextEditingController ctrl,
      String tipe, ValueChanged<String?> onTipeChange) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 10, right: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: ctrl,
            maxLines: 2,
            decoration: InputDecoration(
                labelText: 'Pernyataan $label',
                border: const OutlineInputBorder()),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: DropdownButtonFormField<String>(
            value: tipe,
            decoration: const InputDecoration(
                labelText: 'Tipe', border: OutlineInputBorder()),
            items: _tipeOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: onTipeChange,
          ),
        ),
      ],
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final isEdit = widget.soalEdit != null;

      // Gunakan countByMetode agar nomor urut per-metode akurat
      final no = isEdit
          ? widget.soalEdit!.no
          : await _repo.countByMetode(MetodeSoal.pairedComparison) + 1;

      final soal = SoalRiasec(
        docId: widget.soalEdit?.docId,
        no: no,
        metode: MetodeSoal.pairedComparison,
        pernyataanA: _pernyataanACtrl.text.trim(),
        tipeA: _tipeA,
        pernyataanB: _pernyataanBCtrl.text.trim(),
        tipeB: _tipeB,
      );

      // Debug — cek data sebelum kirim ke Firestore
      debugPrint('📤 Data yang dikirim: ${soal.toFirestore()}');

      if (isEdit) {
        await _repo.update(soal.docId!, soal);
      } else {
        await _repo.tambah(soal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? '✅ Soal berhasil diperbarui!'
                : '✅ Soal berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      // ⬅️ Tangkap error yang sebelumnya hilang!
      debugPrint('❌ Error simpan soal: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

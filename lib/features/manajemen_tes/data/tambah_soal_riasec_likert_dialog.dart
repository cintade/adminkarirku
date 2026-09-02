import 'package:flutter/material.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_riasec_model.dart';
import 'package:adminkarieku/features/manajemen_tes/data/repositories/soal_riasec_repository.dart';

class TambahSoalRiasecLikertDialog extends StatefulWidget {
  final SoalRiasec? soalEdit;
  const TambahSoalRiasecLikertDialog({super.key, this.soalEdit});

  @override
  State<TambahSoalRiasecLikertDialog> createState() =>
      _TambahSoalRiasecLikertDialogState();
}

class _TambahSoalRiasecLikertDialogState
    extends State<TambahSoalRiasecLikertDialog> {
  final _repo = SoalRiasecRepository();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pernyataanCtrl;
  String _tipe = 'R';
  bool _loading = false;

  static const _tipeOptions = ['R', 'I', 'A', 'S', 'E', 'C'];

  @override
  void initState() {
    super.initState();
    _pernyataanCtrl =
        TextEditingController(text: widget.soalEdit?.pernyataan ?? '');
    _tipe = widget.soalEdit?.tipe ?? 'R';
  }

  @override
  void dispose() {
    _pernyataanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.soalEdit != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Soal Likert' : 'Tambah Soal Likert'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pernyataanCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Pernyataan',
                    border: OutlineInputBorder(),
                    hintText:
                        'Contoh: Saya menikmati bekerja dengan tangan saya'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipe,
                decoration: const InputDecoration(
                    labelText: 'Tipe RIASEC', border: OutlineInputBorder()),
                items: _tipeOptions
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(_tipeLabel(t))))
                    .toList(),
                onChanged: (v) => setState(() => _tipe = v!),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Skala: 1 = Sangat Tidak Setuju · 5 = Sangat Setuju\nJawaban mahasiswa disimpan di sisi mobile.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
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

  String _tipeLabel(String t) {
    const map = {
      'R': 'R — Realistic',
      'I': 'I — Investigative',
      'A': 'A — Artistic',
      'S': 'S — Social',
      'E': 'E — Enterprising',
      'C': 'C — Conventional',
    };
    return map[t] ?? t;
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final isEdit = widget.soalEdit != null;
      final no = isEdit
          ? widget.soalEdit!.no
          : await _repo.countByMetode(MetodeSoal.likert) + 1;
      final soal = SoalRiasec(
        docId: widget.soalEdit?.docId,
        no: no,
        metode: MetodeSoal.likert,
        pernyataan: _pernyataanCtrl.text.trim(),
        tipe: _tipe,
      );
      if (isEdit) {
        await _repo.update(soal.docId!, soal);
      } else {
        await _repo.tambah(soal);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

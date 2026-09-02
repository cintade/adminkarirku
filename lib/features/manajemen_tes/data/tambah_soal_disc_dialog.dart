import 'package:flutter/material.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_disc_model.dart';
import 'package:adminkarieku/features/manajemen_tes/data/repositories/soal_disc_repository.dart';

class TambahSoalDiscDialog extends StatefulWidget {
  final SoalDisc? soalEdit;
  const TambahSoalDiscDialog({super.key, this.soalEdit});

  @override
  State<TambahSoalDiscDialog> createState() =>
      _TambahSoalDiscDialogState();
}

class _TambahSoalDiscDialogState extends State<TambahSoalDiscDialog> {
  final _repo = SoalDiscRepository();
  final _formKey = GlobalKey<FormState>();

  // 4 kata sifat — index 0=D, 1=I, 2=S, 3=C
  final _kataCtrls = List.generate(4, (_) => TextEditingController());
  static const _dimensiUrut = [
    DimensiDisc.dominance,
    DimensiDisc.influence,
    DimensiDisc.steadiness,
    DimensiDisc.conscientiousness,
  ];
  static const _discColors = {
    DimensiDisc.dominance: Color(0xFFDC2626),
    DimensiDisc.influence: Color(0xFFD97706),
    DimensiDisc.steadiness: Color(0xFF16A34A),
    DimensiDisc.conscientiousness: Color(0xFF2563EB),
  };
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.soalEdit;
    if (s != null && s.kataSifat.isNotEmpty) {
      for (final kata in s.kataSifat) {
        final idx = _dimensiUrut.indexOf(kata.dimensi);
        if (idx >= 0) _kataCtrls[idx].text = kata.teks;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _kataCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.soalEdit != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Soal DISC' : 'Tambah Soal DISC'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info cara pengisian
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Format Most & Least',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.blue)),
                    SizedBox(height: 4),
                    Text(
                      'Isi 4 kata sifat, masing-masing mewakili dimensi D / I / S / C.\n'
                      'Mahasiswa akan memilih:\n'
                      '  • Most (M) — kata yang PALING menggambarkan dirinya\n'
                      '  • Least (L) — kata yang PALING TIDAK menggambarkan dirinya',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              // Input 4 kata sifat
              ...List.generate(4, (i) {
                final dimensi = _dimensiUrut[i];
                final color = _discColors[dimensi] ?? Colors.grey;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Badge dimensi
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(
                            dimensi.singkatan,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: color),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _kataCtrls[i],
                          decoration: InputDecoration(
                            labelText: dimensi.label,
                            labelStyle: TextStyle(color: color),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: color.withOpacity(0.4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: color, width: 1.5),
                            ),
                            hintText: _hintText(dimensi),
                            isDense: true,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Wajib diisi'
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Preview tampilan mobile
              const Text('Preview tampilan di mobile:',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(4, (i) {
                  final dimensi = _dimensiUrut[i];
                  final color = _discColors[dimensi] ?? Colors.grey;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _kataCtrls[i].text.isNotEmpty
                                ? _kataCtrls[i].text
                                : '—',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _previewBtn('M', Colors.green),
                              const SizedBox(width: 3),
                              _previewBtn('L', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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

  Widget _previewBtn(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.w700)),
      );

  String _hintText(DimensiDisc d) {
    switch (d) {
      case DimensiDisc.dominance:
        return 'Contoh: Tegas, Berani';
      case DimensiDisc.influence:
        return 'Contoh: Ramah, Optimis';
      case DimensiDisc.steadiness:
        return 'Contoh: Sabar, Setia';
      case DimensiDisc.conscientiousness:
        return 'Contoh: Teliti, Sistematis';
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final isEdit = widget.soalEdit != null;
      final no = isEdit
          ? widget.soalEdit!.no
          : await _repo.countSoal() + 1;
      final kataSifat = List.generate(
        4,
        (i) => KataSifatDisc(
          teks: _kataCtrls[i].text.trim(),
          dimensi: _dimensiUrut[i],
        ),
      );
      final soal = SoalDisc(
        docId: widget.soalEdit?.docId,
        no: no,
        kataSifat: kataSifat,
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
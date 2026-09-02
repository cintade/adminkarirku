import 'package:flutter/material.dart';
import 'package:adminkarieku/features/manajemen_tes/data/models/soal_sternberg_model.dart';
import 'package:adminkarieku/features/manajemen_tes/data/repositories/soal_sterberg_repository.dart';

class TambahSoalSternbergDialog extends StatefulWidget {
  final SoalSternberg? soalEdit;
  final int? defaultPart; // pre-select part jika dibuka dari tab part tertentu

  const TambahSoalSternbergDialog({
    super.key,
    this.soalEdit,
    this.defaultPart,
  });

  @override
  State<TambahSoalSternbergDialog> createState() =>
      _TambahSoalSternbergDialogState();
}

class _TambahSoalSternbergDialogState extends State<TambahSoalSternbergDialog> {
  final _repo = SoalSternbergRepository();
  final _formKey = GlobalKey<FormState>();

  late int _noPart;
  late final TextEditingController _pernyataanCtrl;
  late final TextEditingController _konteksCtrl;
  late final TextEditingController _gambarSoalUrlCtrl;
  final _pilihanCtrls = List.generate(4, (_) => TextEditingController());
  final _gambarPilihanCtrls = List.generate(4, (_) => TextEditingController());
  static const _huruf = ['A', 'B', 'C', 'D'];
  String _jawabanBenar = 'A';
  bool _loading = false;
  bool _showKonteks = false;
  bool _showGambarSoal = false;

  // Warna per dimensi
  static const _dimensiColor = {
    DimensiSternberg.analitis: Color(0xFF2563EB),
    DimensiSternberg.kreatif: Color(0xFFD97706),
    DimensiSternberg.praktis: Color(0xFF16A34A),
  };

  @override
  void initState() {
    super.initState();
    final s = widget.soalEdit;
    _noPart = s?.noPart ?? widget.defaultPart ?? 1;
    _pernyataanCtrl = TextEditingController(text: s?.pernyataan ?? '');
    _konteksCtrl = TextEditingController(text: s?.konteks ?? '');
    _gambarSoalUrlCtrl = TextEditingController(text: s?.gambarSoalUrl ?? '');
    _jawabanBenar = s?.jawabanBenar ?? 'A';
    _showKonteks = (s?.konteks?.isNotEmpty ?? false);
    _showGambarSoal = (s?.gambarSoalUrl?.isNotEmpty ?? false);

    if (s != null) {
      for (int i = 0; i < s.pilihan.length && i < 4; i++) {
        _pilihanCtrls[i].text = s.pilihan[i].teks;
        _gambarPilihanCtrls[i].text = s.pilihan[i].gambarUrl ?? '';
      }
    }
  }

  @override
  void dispose() {
    _pernyataanCtrl.dispose();
    _konteksCtrl.dispose();
    _gambarSoalUrlCtrl.dispose();
    for (final c in _pilihanCtrls) c.dispose();
    for (final c in _gambarPilihanCtrls) c.dispose();
    super.dispose();
  }

  StatPart get _currentPart => StatPart.fromNoPart(_noPart);

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.soalEdit != null;
    final part = _currentPart;
    final dc = _dimensiColor[part.dimensi] ?? Colors.grey;
    final isFigural = part.format == FormatKonten.figural;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: dc.withOpacity(0.06),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: dc.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology_rounded, color: dc, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit
                          ? 'Edit Soal — ${part.label}'
                          : 'Tambah Soal — ${part.label}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15, color: dc),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // ── Form ───────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pilih Part
                      _buildPartPicker(dc),
                      const SizedBox(height: 16),

                      // Info Part terpilih
                      _buildPartInfo(part, dc),
                      const SizedBox(height: 16),

                      // Konteks (opsional)
                      Row(
                        children: [
                          const Text('Konteks / Informasi Pendukung',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('(opsional)',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade400)),
                          const Spacer(),
                          Switch(
                            value: _showKonteks,
                            onChanged: (v) => setState(() => _showKonteks = v),
                            activeColor: dc,
                          ),
                        ],
                      ),
                      if (_showKonteks) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _konteksCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: _hintKonteks(part.format),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Gambar soal (untuk figural)
                      if (isFigural) ...[
                        Row(
                          children: [
                            const Text('URL Gambar Soal',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text('(untuk soal figural)',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade400)),
                            const Spacer(),
                            Switch(
                              value: _showGambarSoal,
                              onChanged: (v) =>
                                  setState(() => _showGambarSoal = v),
                              activeColor: dc,
                            ),
                          ],
                        ),
                        if (_showGambarSoal) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _gambarSoalUrlCtrl,
                            decoration: const InputDecoration(
                              hintText: 'https://...',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.image_outlined),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ],

                      // Pernyataan / Soal
                      const Text('Pernyataan / Soal',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pernyataanCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: _hintPernyataan(part),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Pilihan Jawaban A–D
                      const Text('Pilihan Jawaban (A–D)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        'Klik tombol radio ○ untuk menandai jawaban benar',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(4, (i) {
                        final huruf = _huruf[i];
                        final isBenar = _jawabanBenar == huruf;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Radio<String>(
                                    value: huruf,
                                    groupValue: _jawabanBenar,
                                    onChanged: (v) =>
                                        setState(() => _jawabanBenar = v!),
                                    activeColor: Colors.green,
                                  ),
                                  _circleHuruf(huruf, isBenar),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _pilihanCtrls[i],
                                      decoration: InputDecoration(
                                        labelText: 'Pilihan $huruf',
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: isBenar
                                                  ? Colors.green
                                                  : Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color:
                                                  isBenar ? Colors.green : dc),
                                        ),
                                        isDense: true,
                                        suffixIcon: isBenar
                                            ? const Icon(Icons.check_circle,
                                                color: Colors.green, size: 18)
                                            : null,
                                      ),
                                      validator: (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Wajib diisi'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              // URL gambar pilihan (untuk figural)
                              if (isFigural)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 64, top: 4),
                                  child: TextFormField(
                                    controller: _gambarPilihanCtrls[i],
                                    decoration: InputDecoration(
                                      hintText:
                                          'URL gambar pilihan $huruf (opsional)',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      prefixIcon: const Icon(
                                          Icons.image_outlined,
                                          size: 16),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // ── Actions ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Text(
                    'Jawaban benar: $_jawabanBenar',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                  const Spacer(),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : _simpan,
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Soal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget Helpers ────────────────────────────────────────────────────────
  Widget _buildPartPicker(Color dc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Part',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: StatPart.semuaPart.map((part) {
            final isSelected = _noPart == part.noPart;
            final color = _dimensiColor[part.dimensi] ?? Colors.grey;
            return GestureDetector(
              onTap: () => setState(() => _noPart = part.noPart),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.12)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1),
                ),
                child: Column(
                  children: [
                    Text('Part ${part.noPart}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? color : Colors.grey.shade600)),
                    Text(
                      '${part.dimensi.label}\n${part.format.label}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9,
                          color: isSelected
                              ? color.withOpacity(0.8)
                              : Colors.grey.shade400,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPartInfo(StatPart part, Color dc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dc.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dc.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: dc),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _infoTipe(part),
              style: TextStyle(fontSize: 12, color: dc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleHuruf(String huruf, bool isBenar) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isBenar ? Colors.green.shade100 : Colors.grey.shade100,
          border:
              Border.all(color: isBenar ? Colors.green : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(huruf,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color:
                      isBenar ? Colors.green.shade700 : Colors.grey.shade600)),
        ),
      );

  // ── Hint teks sesuai tipe ─────────────────────────────────────────────────
  String _hintPernyataan(StatPart part) {
    switch (part.format) {
      case FormatKonten.verbal:
        return part.dimensi == DimensiSternberg.analitis
            ? 'Contoh: Lawyer adalah dokter, seperti _____ adalah _____'
            : part.dimensi == DimensiSternberg.kreatif
                ? 'Contoh: Jika kucing bisa terbang, apa yang terjadi?'
                : 'Contoh: Anda terlambat rapat karena macet. Apa yang Anda lakukan?';
      case FormatKonten.kuantitatif:
        return part.dimensi == DimensiSternberg.analitis
            ? 'Contoh: Jika 3x + 5 = 20, berapakah x?'
            : part.dimensi == DimensiSternberg.kreatif
                ? 'Contoh: Berapa cara berbeda untuk membuat 10 dari 4 angka?'
                : 'Contoh: Anda punya anggaran 500.000. Bagaimana Anda mengalokasikannya?';
      case FormatKonten.figural:
        return 'Deskripsikan pola/gambar soal, atau upload gambar via URL';
    }
  }

  String _hintKonteks(FormatKonten format) {
    switch (format) {
      case FormatKonten.verbal:
        return 'Bacaan / paragraf teks yang menjadi konteks soal';
      case FormatKonten.kuantitatif:
        return 'Data, tabel, atau informasi angka pendukung';
      case FormatKonten.figural:
        return 'Deskripsi pola gambar atau instruksi figural';
    }
  }

  String _infoTipe(StatPart part) {
    final dimensiDesc = {
      DimensiSternberg.analitis:
          'Analitis: menganalisis, membandingkan, mengevaluasi, mengkritik',
      DimensiSternberg.kreatif:
          'Kreatif: menciptakan, menemukan, mengimajinasikan, bereksperimen',
      DimensiSternberg.praktis:
          'Praktis: menerapkan, menggunakan, mempraktikkan dalam kehidupan nyata',
    };
    final formatDesc = {
      FormatKonten.verbal: 'Format Verbal: soal berbasis teks/bahasa',
      FormatKonten.kuantitatif:
          'Format Kuantitatif: soal berbasis angka/matematika',
      FormatKonten.figural: 'Format Figural: soal berbasis gambar/pola visual',
    };
    return '${dimensiDesc[part.dimensi]}\n${formatDesc[part.format]}';
  }

  // ── Simpan ke Firestore ───────────────────────────────────────────────────
  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final isEdit = widget.soalEdit != null;

    try {
      final noSoal = isEdit
          ? widget.soalEdit!.noSoal
          : await _repo.nextNoSoalInPart(_noPart);
      final part = StatPart.fromNoPart(_noPart);
      final pilihan = List.generate(4, (i) {
        final gambarUrl = _gambarPilihanCtrls[i].text.trim();
        return PilihanJawaban(
          huruf: _huruf[i],
          teks: _pilihanCtrls[i].text.trim(),
          gambarUrl: gambarUrl.isNotEmpty ? gambarUrl : null,
        );
      });
      final gambarSoalUrl = _gambarSoalUrlCtrl.text.trim();
      final konteks = _konteksCtrl.text.trim();
      final soal = SoalSternberg(
        docId: widget.soalEdit?.docId,
        noSoal: noSoal,
        noPart: _noPart,
        dimensi: part.dimensi,
        format: part.format,
        pernyataan: _pernyataanCtrl.text.trim(),
        gambarSoalUrl: gambarSoalUrl.isNotEmpty ? gambarSoalUrl : null,
        konteks: konteks.isNotEmpty ? konteks : null,
        pilihan: pilihan,
        jawabanBenar: _jawabanBenar,
      );

      if (isEdit) {
        await _repo.update(soal.docId!, soal);
      } else {
        await _repo.tambah(soal);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(isEdit
                    ? 'Soal Part $_noPart berhasil diperbarui'
                    : 'Soal Part $_noPart berhasil ditambahkan'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal menyimpan: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

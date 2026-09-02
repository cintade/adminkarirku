import 'package:flutter/material.dart';
import 'package:adminkarieku/features/karir/data/karir_model.dart';
import 'package:adminkarieku/features/karir/data/karir_repository.dart';
import 'package:adminkarieku/features/aturan_rekomendasi_karir/data/aturan_rekomendasi_model.dart';
import 'package:adminkarieku/features/aturan_rekomendasi_karir/data/aturan_rekomendasi_repository.dart';

class EditAturanRekomendasiScreen extends StatefulWidget {
  final AturanRekomendasiModel? aturan;
  // Jika dibuka dari halaman detail karir tertentu, kr_id sudah fix
  // dan dropdown karir tidak perlu ditampilkan/diubah.
  final String? krIdTerkunci;

  const EditAturanRekomendasiScreen({
    super.key,
    this.aturan,
    this.krIdTerkunci,
  });

  @override
  State<EditAturanRekomendasiScreen> createState() =>
      _EditAturanRekomendasiScreenState();
}

class _EditAturanRekomendasiScreenState
    extends State<EditAturanRekomendasiScreen> {
  final _repo = AturanRekomendasiRepository();
  final _karirRepo = KarirRepository();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loadingKarir = true;
  List<Map<String, String>> _daftarKarir = [];

  String? _krIdDipilih;
  late TipeRiasec _riasecDominan1;
  late TipeRiasec _riasecDominan2;
  late TipeDisc _disc;
  late KategoriBakat _bakat;
  late JenjangPendidikan _jenjang;
  late final TextEditingController _prioritasCtrl;

  @override
  void initState() {
    super.initState();
    final a = widget.aturan;
    _krIdDipilih = widget.krIdTerkunci ?? a?.krId;
    _riasecDominan1 = a?.riasecDominan1 ?? TipeRiasec.R;
    _riasecDominan2 = a?.riasecDominan2 ?? TipeRiasec.I;
    _disc = a?.tipeDisc ?? TipeDisc.D;
    _bakat = a?.kategoriBakat ?? KategoriBakat.analitis;
    _jenjang = a?.jenjangPendidikan ?? JenjangPendidikan.semua;
    _prioritasCtrl =
        TextEditingController(text: (a?.prioritasRekomendasi ?? 1).toString());
    _loadKarir();
  }

  Future<void> _loadKarir() async {
    final list = await _karirRepo.getDaftarKarirRingkas();
    if (mounted) {
      setState(() {
        _daftarKarir = list;
        _loadingKarir = false;
      });
    }
  }

  @override
  void dispose() {
    _prioritasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.aturan != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 14, color: Color(0xFF1A1A2E)),
          label: const Text('Kembali',
              style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 13)),
        ),
        leadingWidth: 110,
        title: Text(
          isEdit ? 'Edit Aturan Rekomendasi' : 'Tambah Aturan Rekomendasi',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: ElevatedButton(
              onPressed: _loading ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C3FE0),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                _buildKarirDipilih(),
                const SizedBox(height: 20),
                _buildRiasecCard(),
                const SizedBox(height: 16),
                _buildDropdownCard(
                  title: 'Tipe DISC',
                  child: DropdownButtonFormField<TipeDisc>(
                    value: _disc,
                    decoration: _inputDeco(),
                    items: TipeDisc.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text('${t.kode} — ${t.label}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _disc = v!),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdownCard(
                  title: 'Kategori Bakat (Sternberg STAT)',
                  child: DropdownButtonFormField<KategoriBakat>(
                    value: _bakat,
                    decoration: _inputDeco(),
                    items: KategoriBakat.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text('${t.emoji} ${t.label}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _bakat = v!),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdownCard(
                  title: 'Jenjang Pendidikan',
                  child: DropdownButtonFormField<JenjangPendidikan>(
                    value: _jenjang,
                    decoration: _inputDeco(),
                    items: JenjangPendidikan.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _jenjang = v!),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdownCard(
                  title: 'Prioritas Rekomendasi',
                  child: TextFormField(
                    controller: _prioritasCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco(
                        hint: '1 = prioritas tertinggi, 2, 3, dst...'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) {
                        return 'Isi angka prioritas (mis. 1, 2, 3)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Kartu RIASEC dengan 2 dropdown dominan + pratinjau kombinasi ────────
  Widget _buildRiasecCard() {
    return _Card(
      title: 'Tipe RIASEC Dominan',
      subtitle:
          'Pilih 2 tipe yang paling dominan dari 6 tipe RIASEC (mis. hasil skor tertinggi & kedua tertinggi siswa)',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TipeRiasec>(
                  value: _riasecDominan1,
                  decoration: _inputDeco(hint: 'Dominan 1'),
                  items: TipeRiasec.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.kode} — ${t.label}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _riasecDominan1 = v!;
                      // Dropdown kedua tidak boleh sama dengan yang pertama.
                      if (_riasecDominan2 == _riasecDominan1) {
                        _riasecDominan2 = TipeRiasec.values
                            .firstWhere((t) => t != _riasecDominan1);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TipeRiasec>(
                  value: _riasecDominan2,
                  decoration: _inputDeco(hint: 'Dominan 2'),
                  items: TipeRiasec.values
                      .where((t) => t != _riasecDominan1)
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.kode} — ${t.label}',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _riasecDominan2 = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildKombinasiPreview(),
        ],
      ),
    );
  }

  Widget _buildKombinasiPreview() {
    final warna1 = Color(_riasecDominan1.warnaHex);
    final warna2 = Color(_riasecDominan2.warnaHex);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [warna1.withOpacity(0.10), warna2.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEDF5)),
      ),
      child: Row(
        children: [
          Text('${_riasecDominan1.emoji}${_riasecDominan2.emoji}',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(
            'Kode Holland: ${([
              _riasecDominan1.kode,
              _riasecDominan2.kode
            ]..sort()).join()}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(width: 8),
          Text(
            '(${_riasecDominan1.label} + ${_riasecDominan2.label})',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A9E)),
          ),
        ],
      ),
    );
  }

  Widget _buildKarirDipilih() {
    return _Card(
      title: 'Karir Terkait',
      child: widget.krIdTerkunci != null
          ? _buildKarirTerkunciLabel()
          : _loadingKarir
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _krIdDipilih,
                  decoration: _inputDeco(hint: 'Pilih karir...'),
                  items: _daftarKarir
                      .map((k) => DropdownMenuItem(
                            value: k['id'],
                            child: Text(k['nama'] ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _krIdDipilih = v),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Pilih karir terlebih dulu'
                      : null,
                ),
    );
  }

  Widget _buildKarirTerkunciLabel() {
    final nama = _daftarKarir.firstWhere(
      (k) => k['id'] == widget.krIdTerkunci,
      orElse: () => {'nama': '...'},
    )['nama'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(nama ?? '...', style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildDropdownCard({required String title, required Widget child}) {
    return _Card(title: title, child: child);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_krIdDipilih == null || _krIdDipilih!.isEmpty) return;
    if (_riasecDominan1 == _riasecDominan2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RIASEC dominan 1 dan 2 harus berbeda'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final aturan = AturanRekomendasiModel(
        docId: widget.aturan?.docId,
        krId: _krIdDipilih!,
        riasecDominan1: _riasecDominan1,
        riasecDominan2: _riasecDominan2,
        tipeDisc: _disc,
        kategoriBakat: _bakat,
        jenjangPendidikan: _jenjang,
        prioritasRekomendasi: int.parse(_prioritasCtrl.text.trim()),
      );

      if (widget.aturan != null) {
        await _repo.update(widget.aturan!.docId!, aturan);
      } else {
        await _repo.tambah(aturan);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.aturan != null
                ? '✅ Aturan berhasil diperbarui!'
                : '✅ Aturan berhasil ditambahkan!'),
            backgroundColor: const Color(0xFF43A047),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Helper Widgets (samakan gaya dengan edit_karir_screen.dart) ───────────
class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A9E)),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDeco({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFFAFAFA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF4C3FE0), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}

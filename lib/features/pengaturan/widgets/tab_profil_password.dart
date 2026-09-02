import 'package:flutter/material.dart';
import 'package:adminkarieku/features/pengaturan/data/pengaturan_model.dart';
import 'package:adminkarieku/features/pengaturan/data/pengaturan_repository.dart';

class _C {
  static const primary = Color(0xFF1565C0);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE8ECF0);
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF6B7A8D);
  static const danger = Color(0xFFC62828);
}

class TabProfilPassword extends StatefulWidget {
  const TabProfilPassword({super.key});

  @override
  State<TabProfilPassword> createState() => _TabProfilPasswordState();
}

class _TabProfilPasswordState extends State<TabProfilPassword> {
  final _repo = PengaturanRepository();
  late Future<AdminAccount?> _future;

  final _namaCtrl = TextEditingController();
  bool _menyimpanProfil = false;

  final _passwordLamaCtrl = TextEditingController();
  final _passwordBaruCtrl = TextEditingController();
  final _passwordKonfirmasiCtrl = TextEditingController();
  bool _menyimpanPassword = false;
  bool _obscureLama = true, _obscureBaru = true, _obscureKonfirmasi = true;

  @override
  void initState() {
    super.initState();
    _future = _muatProfil();
  }

  Future<AdminAccount?> _muatProfil() async {
    final profil = await _repo.getProfilSaatIni();
    if (profil != null) _namaCtrl.text = profil.nama;
    return profil;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _passwordLamaCtrl.dispose();
    _passwordBaruCtrl.dispose();
    _passwordKonfirmasiCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpanProfil(String uid) async {
    if (_namaCtrl.text.trim().isEmpty) return;
    setState(() => _menyimpanProfil = true);
    try {
      await _repo.updateProfil(uid: uid, nama: _namaCtrl.text.trim());
      _showSnackbar('Profil berhasil diperbarui ✓');
    } catch (e) {
      _showSnackbar('Gagal menyimpan profil: $e', isError: true);
    } finally {
      if (mounted) setState(() => _menyimpanProfil = false);
    }
  }

  Future<void> _ubahPassword() async {
    if (_passwordBaruCtrl.text.length < 6) {
      _showSnackbar('Password baru minimal 6 karakter', isError: true);
      return;
    }
    if (_passwordBaruCtrl.text != _passwordKonfirmasiCtrl.text) {
      _showSnackbar('Konfirmasi password tidak cocok', isError: true);
      return;
    }
    setState(() => _menyimpanPassword = true);
    try {
      await _repo.ubahPassword(
        passwordLama: _passwordLamaCtrl.text,
        passwordBaru: _passwordBaruCtrl.text,
      );
      _passwordLamaCtrl.clear();
      _passwordBaruCtrl.clear();
      _passwordKonfirmasiCtrl.clear();
      _showSnackbar('Password berhasil diubah ✓');
    } catch (e) {
      _showSnackbar('Gagal mengubah password: ${_pesanErorFirebase(e)}',
          isError: true);
    } finally {
      if (mounted) setState(() => _menyimpanPassword = false);
    }
  }

  String _pesanErorFirebase(Object e) {
    final s = e.toString();
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return 'Password lama salah';
    }
    if (s.contains('requires-recent-login')) {
      return 'Sesi login terlalu lama, silakan logout lalu login ulang dan coba lagi';
    }
    return s;
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _C.danger : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAccount?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final profil = snap.data;
        if (profil == null) {
          return const Center(
              child: Text('Gagal memuat profil. Silakan login ulang.'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 720;
              final kartuProfil = _buildKartuProfil(profil);
              final kartuPassword = _buildKartuPassword();
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: kartuProfil),
                    const SizedBox(width: 20),
                    Expanded(child: kartuPassword),
                  ],
                );
              }
              return Column(
                children: [
                  kartuProfil,
                  const SizedBox(height: 20),
                  kartuPassword,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildKartuProfil(AdminAccount profil) {
    return _kartu(
      title: 'Profil Admin',
      icon: Icons.person_outline_rounded,
      children: [
        _label('Nama'),
        TextField(
            controller: _namaCtrl,
            decoration: _inputDecoration('Nama lengkap')),
        const SizedBox(height: 14),
        _label('Email'),
        TextField(
          enabled: false,
          controller: TextEditingController(text: profil.email),
          decoration: _inputDecoration('Email').copyWith(
            suffixIcon: const Tooltip(
              message: 'Email tidak bisa diubah di sini',
              child: Icon(Icons.lock_outline_rounded, size: 16),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _label('Role'),
        TextField(
          enabled: false,
          controller: TextEditingController(text: profil.role),
          decoration: _inputDecoration('Role'),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _menyimpanProfil ? null : () => _simpanProfil(profil.uid),
            style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13)),
            child: _menyimpanProfil
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Simpan Profil'),
          ),
        ),
      ],
    );
  }

  Widget _buildKartuPassword() {
    return _kartu(
      title: 'Ubah Password',
      icon: Icons.lock_outline_rounded,
      children: [
        _label('Password Lama'),
        _passwordField(_passwordLamaCtrl, _obscureLama,
            () => setState(() => _obscureLama = !_obscureLama)),
        const SizedBox(height: 14),
        _label('Password Baru'),
        _passwordField(_passwordBaruCtrl, _obscureBaru,
            () => setState(() => _obscureBaru = !_obscureBaru)),
        const SizedBox(height: 14),
        _label('Konfirmasi Password Baru'),
        _passwordField(_passwordKonfirmasiCtrl, _obscureKonfirmasi,
            () => setState(() => _obscureKonfirmasi = !_obscureKonfirmasi)),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _menyimpanPassword ? null : _ubahPassword,
            style: OutlinedButton.styleFrom(
                foregroundColor: _C.primary,
                padding: const EdgeInsets.symmetric(vertical: 13)),
            child: _menyimpanPassword
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Ubah Password'),
          ),
        ),
      ],
    );
  }

  Widget _passwordField(
      TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: _inputDecoration('').copyWith(
        suffixIcon: IconButton(
          icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _C.textSecondary)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  Widget _kartu(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: _C.primary),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _C.textPrimary)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

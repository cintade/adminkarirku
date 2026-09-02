import 'package:flutter/material.dart';

/// Badge kecil untuk menampilkan label prioritas (P1..P5), warna
/// menyesuaikan tingkat prioritas seperti pada desain UI admin.
class PriorityBadge extends StatelessWidget {
  final int priority;

  const PriorityBadge({super.key, required this.priority});

  ({Color bg, Color fg}) get _colors {
    switch (priority) {
      case 5:
        return (bg: const Color(0xFFEDEBFF), fg: const Color(0xFF5B4FE5));
      case 4:
        return (bg: const Color(0xFFDCEEFE), fg: const Color(0xFF2F80ED));
      case 3:
        return (bg: const Color(0xFFE3F8E9), fg: const Color(0xFF1F9254));
      case 2:
        return (bg: const Color(0xFFFFF3D6), fg: const Color(0xFFC78A00));
      default:
        return (bg: const Color(0xFFF1F1F1), fg: const Color(0xFF6B6B6B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'P$priority',
        style: TextStyle(
          color: c.fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

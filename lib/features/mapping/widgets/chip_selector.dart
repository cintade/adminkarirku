import 'package:flutter/material.dart';

/// Pilihan berbentuk chip — mendukung mode single-select (mis. Sternberg
/// Dominan) maupun multi-select (mis. RIASEC, DISC).
class ChipSelector extends StatelessWidget {
  final List<MapEntry<String, String>> options; // value -> label
  final List<String> selected;
  final bool multiSelect;
  final ValueChanged<List<String>> onChanged;

  const ChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.multiSelect = true,
  });

  void _toggle(String value) {
    final newSelected = List<String>.from(selected);
    if (multiSelect) {
      if (newSelected.contains(value)) {
        newSelected.remove(value);
      } else {
        newSelected.add(value);
      }
    } else {
      newSelected
        ..clear()
        ..add(value);
    }
    onChanged(newSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt.key);
        return ChoiceChip(
          label: Text(opt.value),
          selected: isSelected,
          onSelected: (_) => _toggle(opt.key),
          selectedColor: const Color(0xFF1B2559),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          backgroundColor: const Color(0xFFF7F7FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? const Color(0xFF1B2559) : const Color(0xFFE0E0EA),
            ),
          ),
        );
      }).toList(),
    );
  }
}

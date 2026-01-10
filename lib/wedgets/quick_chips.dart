import 'package:flutter/material.dart';

class QuickChips extends StatelessWidget {
  final List<String> chips;
  final void Function(String) onTap;

  const QuickChips({super.key, required this.chips, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) {
        return ActionChip(
          label: Text(c),
          onPressed: () => onTap(c),
        );
      }).toList(),
    );
  }
}
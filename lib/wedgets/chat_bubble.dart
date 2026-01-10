import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isUser ? scheme.primary.withOpacity(0.22) : Colors.white.withOpacity(0.08);
    final bd = isUser ? scheme.primary.withOpacity(0.35) : Colors.white.withOpacity(0.10);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bd),
        ),
        child: Text(text, style: const TextStyle(height: 1.35)),
      ),
    );
  }
}
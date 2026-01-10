import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/quick_chips.dart';

class KidsBotScreen extends StatefulWidget {
  const KidsBotScreen({super.key});

  @override
  State<KidsBotScreen> createState() => _KidsBotScreenState();
}

class _KidsBotScreenState extends State<KidsBotScreen> {
  final input = TextEditingController();
  final messages = <Map<String, dynamic>>[
    {'role': 'ai', 'text': 'やあ！クイズAIだよ。\n「行きモード」は説明多め。\n「帰りモード」は正解をためて“島博士”になろう！'}
  ];

  bool busy = false;
  String mode = 'going'; // going / return
  int correctCount = 0;

  final quickGoing = const ['クイズ出して！', '島の名物クイズ', '地図の場所クイズ'];
  final quickReturn = const ['帰りモードでクイズ！', 'むずかしめで！', '島博士になりたい'];

  Future<void> send(String text) async {
    if (text.trim().isEmpty || busy) return;
    setState(() {
      busy = true;
      messages.add({'role': 'user', 'text': text.trim()});
    });

    final reply = await ApiClient.sendChat(
      bot: 'kids',
      message: text.trim(),
      uiState: {
        'mode': mode,
        'score': {'correctCount': correctCount},
      },
    );

    // デモ：AIが文中に [CORRECT] を含めたら正解として加点（運用で改善可能）
    final isCorrect = reply.contains('[CORRECT]');
    setState(() {
      messages.add({'role': 'ai', 'text': reply.replaceAll('[CORRECT]', '').trim()});
      if (isCorrect) correctCount += 1;
      busy = false;
      input.clear();
    });

    if (mode == 'return' && correctCount >= 5) {
      setState(() {
        messages.add({
          'role': 'ai',
          'text': '🏅 おめでとう！君は今日から「島博士」だ！\nまた来て島の新しい発見をしよう！'
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = mode == 'going' ? quickGoing : quickReturn;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070A12), Color(0xFF1B1030), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  return ChatBubble(text: m['text'], isUser: m['role'] == 'user');
                },
              ),
            ),
            if (!busy)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: QuickChips(chips: chips, onTap: (c) => send(c)),
              ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(Icons.quiz),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('クイズAI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('モード: ${mode == 'going' ? '行き' : '帰り'} / 正解: $correctCount',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'going', label: Text('行き')),
              ButtonSegment(value: 'return', label: Text('帰り')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => setState(() {
              mode = s.first;
              correctCount = 0; // モード切替でリセット（仕様。必要なら保持に変更）
            }),
          ),
          if (busy) ...[
            const SizedBox(width: 10),
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ]
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: input,
              onSubmitted: (v) => send(v),
              decoration: const InputDecoration(
                hintText: '例：クイズ出して！ / もう一問！',
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: () => send(input.text),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
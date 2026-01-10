import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/quick_chips.dart';

class IslandBotScreen extends StatefulWidget {
  const IslandBotScreen({super.key});

  @override
  State<IslandBotScreen> createState() => _IslandBotScreenState();
}

class _IslandBotScreenState extends State<IslandBotScreen> {
  final input = TextEditingController();
  final messages = <Map<String, dynamic>>[
    {
      'role': 'ai',
      'text': 'こんにちは！島ナビAIです。\n「今日やってるイベント」「今開いてる店」「移動手段（バス/自転車）」など聞いてください。'
    }
  ];

  bool busy = false;

  // “よく開いてる店中心”などの運用ルールをUI側でも補助
  final quick = const [
    '今日のイベント教えて',
    '今開いてるご飯屋さん',
    '自転車レンタル空いてる？',
    'バスの運行状況は？',
    '家族向けのおすすめ'
  ];

  Future<void> send(String text) async {
    if (text.trim().isEmpty || busy) return;
    setState(() {
      busy = true;
      messages.add({'role': 'user', 'text': text.trim()});
    });

    final reply = await ApiClient.sendChat(
      bot: 'island',
      message: text.trim(),
      uiState: {
        'policy': {
          'preferReliableOpenShops': true, // “よく開いてる店中心”
          'alwaysMentionEvents': true,
        },
      },
    );

    setState(() {
      messages.add({'role': 'ai', 'text': reply});
      busy = false;
      input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070A12), Color(0xFF0B1224), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                child: QuickChips(chips: quick, onTap: (c) => send(c)),
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
            child: const Icon(Icons.travel_explore),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('島ナビAI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('イベント・店・交通をまとめて提案', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          if (busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
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
                hintText: '例：今日のイベントは？ / 港から展望台までの行き方',
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
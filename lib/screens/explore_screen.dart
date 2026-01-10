import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('探索', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '※発表用プロトタイプ：\n'
                  '・本番ではここに「カテゴリ別スポット一覧」「現在地から近い順」「雨の日」などを追加\n'
                  '・MapはWebで安定しやすい実装（静的/埋め込み）に寄せるのが安全',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
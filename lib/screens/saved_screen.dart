import 'package:flutter/material.dart';
import '../services/favorites_store.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    items = await FavoritesStore.load();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.bookmark_border),
                SizedBox(width: 8),
                Text('保存', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('まだ保存がありません'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final it = items[i];
                        return Card(
                          child: ListTile(
                            title: Text(it['name'] ?? ''),
                            subtitle: Text(it['category'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await FavoritesStore.removeById(it['id']);
                                await _load();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
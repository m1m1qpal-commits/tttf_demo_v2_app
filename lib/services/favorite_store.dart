import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStore {
  static const _key = 'favorites_v1';

  static Future<List<Map<String, dynamic>>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list;
  }

  static Future<void> save(List<Map<String, dynamic>> items) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(items));
  }

  static Future<void> add(Map<String, dynamic> item) async {
    final items = await load();
    final id = item['id'];
    if (items.any((e) => e['id'] == id)) return;
    items.add(item);
    await save(items);
  }

  static Future<void> removeById(String id) async {
    final items = await load();
    items.removeWhere((e) => e['id'] == id);
    await save(items);
  }
}
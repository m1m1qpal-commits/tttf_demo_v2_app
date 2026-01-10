import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  /// Netlify: netlify.toml の redirect により /api/* が functions に行く
  static const String _base = '/api';

  static Future<String> sendChat({
    required String bot,
    required String message,
    required Map<String, dynamic> uiState,
  }) async {
    final uri = Uri.parse('$_base/ai_chat');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bot': bot,                 // 'island' or 'kids'
        'message': message,
        'uiState': uiState,         // mode, profile, etc
      }),
    );

    if (res.statusCode != 200) {
      return 'エラーが発生しました（${res.statusCode}）。サーバ設定を確認してください。';
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['reply'] as String?) ?? '返答が空でした。';
  }
}
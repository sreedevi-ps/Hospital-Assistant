import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ResponseResult {
  final String key;
  final String value;
  ResponseResult({required this.key, required this.value});
}

class ResponseMapper {
  static Map<String, String> _responseMap = {};
  static Map<String, String> _answerMap = {};
  static bool _initialized = false;

  static Future<void> loadMappings() async {
    if (_initialized) return;

    try {
      final responseJson = await rootBundle.loadString('assets/data/responses.json');
      final answerJson = await rootBundle.loadString('assets/data/answers.json');

      _responseMap = Map<String, String>.from(json.decode(responseJson));
      _answerMap = Map<String, String>.from(json.decode(answerJson));

      _initialized = true;
      print("✅ ResponseMapper loaded successfully.");
    } catch (e, st) {
      print("❌ Failed to load response mappings: $e");
      print("🧵 $st");
    }
  }

  static ResponseResult getResponse(String userQuery) {
    final query = userQuery.trim().toLowerCase();

    // Exact match
    if (_responseMap.containsKey(query)) {
      final key = _responseMap[query]!;
      final response = _answerMap[key] ?? _answerMap['unknown_request']!;
      return ResponseResult(key: key, value: response);
    }

    // Approximate match
    for (var entry in _responseMap.entries) {
      if (query.contains(entry.key)) {
        final key = entry.value;
        final response = _answerMap[key] ?? _answerMap['unknown_request']!;
        return ResponseResult(key: key, value: response);
      }
    }

    return ResponseResult(
        key: 'unknown_request', value: _answerMap['unknown_request']!);
  }
}

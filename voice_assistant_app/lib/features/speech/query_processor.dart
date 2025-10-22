import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ResponseMapper {
  static Map<String, String> _queryToKey = {};
  static Map<String, String> _keyToAnswer = {};

  static Future<void> loadMappings() async {
    final queryData = await rootBundle.loadString('assets/responses.json');
    final answerData = await rootBundle.loadString('assets/answers.json');

    _queryToKey = Map<String, String>.from(json.decode(queryData));
    _keyToAnswer = Map<String, String>.from(json.decode(answerData));
  }

  static String getReply(String query) {
    final key = _queryToKey[query.trim()] ?? "unknown_request";
    return _keyToAnswer[key] ?? "ക്ഷമിക്കണം, ഞാൻ മനസ്സിലായില്ല.";
  }
}

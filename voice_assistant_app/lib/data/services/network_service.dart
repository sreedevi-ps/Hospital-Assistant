import 'package:dio/dio.dart';

class NetworkService {
  final Dio _dio = Dio();
  final String _baseUrl =
      "https://p09r0btf-5005.inc1.devtunnels.ms/"; 

  /// Send user query to backend and get structured response
 Future<Map<String, String?>> getResponseKey(String userQuery, String? sessionId) async {
  try {
    final response = await _dio.post(
      '$_baseUrl/query',
      data: {
        "query": userQuery,
        if (sessionId != null) "session_id": sessionId,
      },
      options: Options(
        headers: {"Content-Type": "application/json"},
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;

      // ✅ Adapt parsing: sometimes wrapped, sometimes flat
      final key = data["key"] ??
          data["response"]?["key"];
      final answer = data["answer"] ??
          data["response"]?["answer"];
      final sessionIdResp = data["session_id"];

      print("✅ Query: $userQuery, Key: $key, Answer: $answer, Session ID: $sessionIdResp");

      return {
        "key": key ?? "unknown_request",
        "answer": answer,
        "session_id": sessionIdResp ?? sessionId
      };
    } else {
      print("❗ Invalid response: ${response.data}");
      return {"key": "unknown_request", "answer": null, "session_id": sessionId};
    }
  } catch (e) {
    print("❗ Network error for query '$userQuery': $e");
    return {"key": "unknown_request", "answer": null, "session_id": sessionId};
  }
}


  /// Reset the backend session
  Future<bool> resetSession(String sessionId) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/reset_session',
        data: {"session_id": sessionId},
        options: Options(
          headers: {"Content-Type": "application/json"},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        print("🔄 Session reset: $sessionId");
        return true;
      } else {
        print("❗ Failed to reset session: ${response.data}");
        return false;
      }
    } catch (e) {
      print("❗ Network error while resetting session: $e");
      return false;
    }
  }
}

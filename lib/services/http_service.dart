import 'package:http/http.dart' as http;
import 'dart:convert';

const String authTokenKey = 'auth_token';

class HttpService {
  final String baseUrl;
  String? _token;

  HttpService({required this.baseUrl});

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'An error occurred',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      print('[HTTP] GET $endpoint with token: ${_token?.substring(0, 20)}...');
      final response = await http.get(url, headers: headers);
      print('[HTTP] Response status: ${response.statusCode} for $endpoint');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('[HTTP] Error response: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          throw Exception('API Error (${response.statusCode}): ${errorData['message'] ?? response.body}');
        } catch (e) {
          throw Exception('API Error (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      print('[HTTP] Exception: $e');
      rethrow;
    }
  }
}

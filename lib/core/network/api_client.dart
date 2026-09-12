import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  // Allow setting base URL or fallback to localhost
  final String baseUrl;
  final TokenStorage _tokenStorage = TokenStorage();

  ApiClient({this.baseUrl = 'http://localhost:8000/api/v1'});

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Unable to connect to server. Please check your network connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await http
          .post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Unable to connect to server. Please check backend status.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network request failed: ${e.toString()}');
    }
  }

  dynamic _processResponse(http.Response response) {
    final bodyString = response.body;
    dynamic jsonBody;

    try {
      jsonBody = jsonDecode(bodyString);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    String errorMessage = 'An unexpected error occurred (${response.statusCode})';
    if (jsonBody is Map && jsonBody.containsKey('detail')) {
      final detail = jsonBody['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else if (detail is List && detail.isNotEmpty) {
        errorMessage = detail.first['msg'] ?? errorMessage;
      }
    }

    throw ApiException(errorMessage, statusCode: response.statusCode);
  }
}

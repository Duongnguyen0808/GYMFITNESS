import 'dart:async'; // Import thêm thư viện này để dùng TimeoutException
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._privateConstructor();
  static final ApiClient instance = ApiClient._privateConstructor();

  // ... (Giữ nguyên phần baseUrl và serverUrl như tôi đã hướng dẫn trước đó) ...
  String get serverUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      // Android Emulator: dùng 10.0.2.2 để kết nối đến localhost của máy host
      return 'http://10.0.2.2:3000';
    }
  }

  String get baseUrl => '$serverUrl/api';

  // ... (Giữ nguyên _getToken, _saveToken, _clearToken, _getHeaders) ...
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true, 'data': null};
      }
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Request failed');
    }
  }

  // --- SỬA CÁC HÀM DƯỚI ĐÂY ĐỂ TĂNG TIMEOUT ---

  // Thời gian chờ mặc định: 30 giây (Thay vì 3 giây như hiện tại)
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var uri = Uri.parse('${baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(
            uri,
            headers: await _getHeaders(includeAuth: includeAuth),
          )
          .timeout(_timeoutDuration); // <--- THÊM DÒNG NÀY

      return _handleResponse(response);
    } on TimeoutException catch (_) {
      throw Exception(
          'Kết nối tới máy chủ quá hạn (Timeout). Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic>? body, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}$endpoint'),
            headers: await _getHeaders(includeAuth: includeAuth),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeoutDuration); // <--- THÊM DÒNG NÀY

      final result = _handleResponse(response);

      if (endpoint.contains('/auth/') && result['data']?['token'] != null) {
        await _saveToken(result['data']['token']);
      }

      return result;
    } on TimeoutException catch (_) {
      throw Exception(
          'Kết nối tới máy chủ quá hạn (Timeout). Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic>? body, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${baseUrl}$endpoint'),
            headers: await _getHeaders(includeAuth: includeAuth),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeoutDuration); // <--- THÊM DÒNG NÀY

      return _handleResponse(response);
    } on TimeoutException catch (_) {
      throw Exception(
          'Kết nối tới máy chủ quá hạn (Timeout). Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${baseUrl}$endpoint'),
            headers: await _getHeaders(includeAuth: includeAuth),
          )
          .timeout(_timeoutDuration); // <--- THÊM DÒNG NÀY

      return _handleResponse(response);
    } on TimeoutException catch (_) {
      throw Exception(
          'Kết nối tới máy chủ quá hạn (Timeout). Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._privateConstructor();
  static final ApiClient instance = ApiClient._privateConstructor();

  // Base URL - tự động detect platform
  // Web: localhost (cho cả admin và user app)
  // Android Emulator: 10.0.2.2
  // iOS Simulator: localhost
  // Physical Device: IP thực tế của máy tính
  String get baseUrl {
    if (kIsWeb) {
      // Web platform (admin app) - dùng localhost
      final url = 'http://localhost:3000/api';
      print('🌐 Web platform detected - Using API: $url');
      return url;
    } else {
      // Mobile platform (user app) - dùng 10.0.2.2 cho Android Emulator
      // Nếu chạy trên physical device, cần thay bằng IP thực tế
      final url = 'http://192.168.1.8:3000/api';
      print('📱 Mobile platform detected - Using API: $url');
      return url;
    }
  }

  // Get token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with authentication
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

  // Handle response
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

      final response = await http.get(
        uri,
        headers: await _getHeaders(includeAuth: includeAuth),
      );

      return _handleResponse(response);
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
      final response = await http.post(
        Uri.parse('${baseUrl}$endpoint'),
        headers: await _getHeaders(includeAuth: includeAuth),
        body: body != null ? json.encode(body) : null,
      );

      final result = _handleResponse(response);

      // Save token if it's a login/register response
      if (endpoint.contains('/auth/') && result['data']?['token'] != null) {
        await _saveToken(result['data']['token']);
      }

      return result;
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
      final response = await http.put(
        Uri.parse('${baseUrl}$endpoint'),
        headers: await _getHeaders(includeAuth: includeAuth),
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
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
      final response = await http.delete(
        Uri.parse('${baseUrl}$endpoint'),
        headers: await _getHeaders(includeAuth: includeAuth),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

/// API Service — base HTTP client for the Matrimony backend
///
/// Base URL is configurable. JWT token is loaded from shared_preferences
/// and attached to every authenticated request as a Bearer header.
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── CHANGE THIS to match your backend deployment ──────────────────────────
  // Development: 'http://10.0.2.2:5001' (Android emulator → localhost)
  // Device on LAN: 'http://192.168.x.x:5001'
  // Production:  'https://apps.plestarinc.com:3010'
  static const String _baseUrl = 'https://apps.plestarinc.com:3010';
  // static const String _baseUrl = 'http://10.0.2.2:5001';

  static const String _tokenKey = 'mat_jwt_token';

  // ─── Token helpers ────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ─── Request helpers ──────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    final now = DateTime.now();
    return {
      'Content-Type': 'application/json',
      'x-timezone-offset': now.timeZoneOffset.inMinutes.toString(),
      'x-client-timezone': now.timeZoneName,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _parseBody(http.Response response) {
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response.'};
    }
  }

  /// GET request with JWT auth
  static Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _authHeaders();
    final response = await http.get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));
    return _parseBody(response);
  }

  /// POST request with JWT auth
  static Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    final response = await http.post(uri,
        headers: headers, body: json.encode(body ?? {}))
        .timeout(const Duration(seconds: 20));
    return _parseBody(response);
  }

  /// PUT request with JWT auth
  static Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    final response = await http.put(uri,
        headers: headers, body: json.encode(body ?? {}))
        .timeout(const Duration(seconds: 20));
    return _parseBody(response);
  }

  /// PATCH request with JWT auth
  static Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    final response = await http.patch(uri,
        headers: headers, body: json.encode(body ?? {}))
        .timeout(const Duration(seconds: 20));
    return _parseBody(response);
  }

  /// DELETE request with JWT auth
  static Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    final response = await http.delete(uri, headers: headers)
        .timeout(const Duration(seconds: 20));
    return _parseBody(response);
  }

  /// Multipart file upload with JWT auth
  static Future<Map<String, dynamic>> uploadFile(
      String path, File file, String fieldName) async {
    final token = await getToken();
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Set correct MIME type so the backend Multer accepts JPEG, PNG, and WebP
    final lower = file.path.toLowerCase();
    MediaType contentType;
    if (lower.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else if (lower.endsWith('.webp')) {
      contentType = MediaType('image', 'webp');
    } else {
      contentType = MediaType('image', 'jpeg');
    }

    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: contentType,
    ));
    final streamedResponse = await request.send()
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    return _parseBody(response);
  }

  static String get baseUrl => _baseUrl;
}

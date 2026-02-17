import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.1.20.55:8282';

  final _storage = const FlutterSecureStorage();

  // ─── LOGIN ─────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _storage.write(key: 'jwt_token', value: data['token']);
        await _storage.write(key: 'username', value: data['username'] ?? username);
        await _storage.write(key: 'full_name', value: data['fullName'] ?? '');
        await _storage.write(key: 'role', value: data['role'] ?? '');

        return {
          'success': true,
          'message': 'Giris basarili',
          'username': data['username'] ?? username,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Kullanici adi veya sifre hatali',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Baglanti hatasi: Sunucuya erisemiyor ($baseUrl)',
      };
    }
  }

  // ─── TOKEN ─────────────────────────────────────────
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  // ─── LOGOUT ────────────────────────────────────────
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ─── AUTH HEADER ───────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── SYNC ──────────────────────────────────────────
  Future<Map<String, dynamic>> syncAllData() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/test/hello'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Veriler basariyla esitlendi',
          'data': jsonDecode(response.body),
        };
      }

      return {
        'success': false,
        'message': 'Sunucuya erisilemedi (${response.statusCode})',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Baglanti hatasi: $e',
      };
    }
  }

  // ─── TEST ──────────────────────────────────────────
  Future<Map<String, dynamic>> testHelloWorld() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/test/hello'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'API hatasi'};
    } catch (e) {
      return {'success': false, 'message': 'Baglanti hatasi: $e'};
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // API Base URL - Emülatör için 10.0.2.2 kullanın (localhost mapping)
  // Gerçek cihaz için PC'nizin IP adresini kullanın
  static const String baseUrl = 'http://10.10.1.84:59558';
  
  final storage = const FlutterSecureStorage();

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
          'rememberMe': false,
        }),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Cookie'yi sakla
          final cookies = response.headers['set-cookie'];
          if (cookies != null) {
            await storage.write(key: 'session_cookie', value: cookies);
          }
          await storage.write(key: 'username', value: username);
          
          return {
            'success': true,
            'message': data['message'] ?? 'Giriş başarılı',
            'username': username,
          };
        }
      }
      
      // Hatalı giriş
      if (response.statusCode == 401) {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Kullanıcı adı veya şifre hatalı',
        };
      }
      
      return {
        'success': false,
        'message': 'Giriş başarısız',
      };
    } catch (e) {
      print('Login Error: $e');
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final cookie = await storage.read(key: 'session_cookie');
    return cookie != null;
  }

  // Get username
  Future<String?> getUsername() async {
    return await storage.read(key: 'username');
  }

  // Logout
  Future<void> logout() async {
    await storage.deleteAll();
  }

  // API Test Endpoint
  Future<Map<String, dynamic>> testHelloWorld() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/test/hello'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      }
      
      return {
        'success': false,
        'message': 'API hatası',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
      };
    }
  }
}

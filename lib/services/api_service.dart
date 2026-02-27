import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  final _dbHelper = DatabaseHelper.instance;

  Future<String> get baseUrl => _dbHelper.getServerUrl();

  // ─── LOGIN ─────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = await baseUrl;
      final response = await http.post(
        Uri.parse('$url/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _storage.write(key: 'jwt_token', value: data['token']);
        await _storage.write(key: 'username', value: data['username'] ?? username);
        await _storage.write(key: 'full_name', value: data['fullName'] ?? '');
        await _storage.write(key: 'role', value: data['role'] ?? '');
        return {'success': true, 'message': 'Giris basarili', 'username': data['username'] ?? username};
      }

      return {'success': false, 'message': data['message'] ?? 'Kullanici adi veya sifre hatali'};
    } catch (e) {
      final url = await baseUrl;
      return {'success': false, 'message': 'Baglanti hatasi: $url adresine erisilemedi'};
    }
  }

  Future<String?> getToken() => _storage.read(key: 'jwt_token');
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }
  Future<String?> getUsername() => _storage.read(key: 'username');
  Future<String?> getRole() => _storage.read(key: 'role');
  Future<void> logout() => _storage.deleteAll();

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

Future<Map<String, dynamic>> syncAllData(String companyCode, String terminalId) async {
  try {
    final url = await baseUrl;
    final headers = await _authHeaders();

    final response = await http.post(
      Uri.parse('$url/api/sync/full-sync'),
      headers: headers,
      body: jsonEncode({
        'companyCode': companyCode,
        'terminalId': terminalId,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'Veriler basariyla esitlendi',
        'data': data,
      };
    } else if (response.statusCode == 401) {
      return {
        'success': false,
        'message': 'Oturum suresi dolmus, tekrar giris yapin',
      };
    } else {
      return {
        'success': false,
        'message': 'Sunucu hatasi (${response.statusCode})',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Baglanti hatasi: $e',
    };
  }
}

  Future<Map<String, dynamic>> sendMrtcData({
    required String companyCode,
    required String terminalId,
    required int prosesId,
    required List<Map<String, dynamic>> mrtcData,
  })   async {
    try {
      final url = await baseUrl;
      final headers = await _authHeaders();

      final response = await http.post(
        Uri.parse('$url/api/mobiledata/send-mrtc'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'terminalId': terminalId,
          'prosesId': prosesId,
          'username': 'mobile_user',
          'mrtcData': mrtcData,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'errorMessage': 'Oturum süresi dolmuş, tekrar giriş yapın',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'errorMessage': data['errorMessage'] ?? 'Sunucu hatası (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errorMessage': 'Bağlantı hatası: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getSeriAmbarBakiye({
    required String companyCode,
    required int subeKodu,
    required String filter,
    String? username,
    String? terminalId,
  }) async {
    try {
      final url = await baseUrl;
      final headers = await _authHeaders();

      final response = await http.post(
        Uri.parse('$url/api/stock/seri-ambar-bakiye'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'subeKodu': subeKodu,
          'filter': filter,
          'username': username ?? '',
          'terminalId': terminalId ?? '',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'errorMessage': 'Oturum süresi dolmuş, tekrar giriş yapın',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'errorMessage': data['errorMessage'] ?? 'Sunucu hatası (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errorMessage': 'Bağlantı hatası: $e',
      };
    }
  }
  Future<Map<String, dynamic>> getSeriDetay({
    required String companyCode,
    required int subeKodu,
    required String seriNo,
    String? username,
    String? terminalId,
  }) async {
    try {
      final url = await baseUrl;
      final headers = await _authHeaders();

      final response = await http.post(
        Uri.parse('$url/api/stock/seri-detay'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'subeKodu': subeKodu,
          'seriNo': seriNo,
          'username': username ?? '',
          'terminalId': terminalId ?? '',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'errorMessage': 'Oturum süresi dolmuş, tekrar giriş yapın',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'errorMessage': data['errorMessage'] ?? 'Sunucu hatası (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errorMessage': 'Bağlantı hatası: $e',
      };
    }
  }
  Future<Map<String, dynamic>> resendLastData({
    required String companyCode,
    required int subeKodu,
    required String terminalId,
    String? username,
  }) async {
    try {
      final url = await baseUrl;
      final headers = await _authHeaders();

      final response = await http.post(
        Uri.parse('$url/api/mobiledata/resend-last'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'subeKodu': subeKodu,
          'terminalId': terminalId,
          'username': username ?? '',
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'],
          'data': data,
        };
      } else {
        return {
          'success': false,
          'errorMessage': 'Sunucu hatası (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'errorMessage': 'Bağlantı hatası: $e',
      };
    }
  }

}

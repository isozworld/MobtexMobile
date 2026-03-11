import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:mobtex_mobile/helpers/session_manager.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  final _dbHelper = DatabaseHelper.instance;

  Future<String> get baseUrl => _dbHelper.getServerUrl();

  // ─── LOGIN ─────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = await baseUrl;

      print('🔍 Login URL: $url/api/auth/login');
      print('🔍 Username: $username');

      // Cihaz bilgilerini al
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceType = 'Mobile';
      String? deviceModel;
      String? osVersion;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }

      final requestBody = {
        'username': username,
        'password': password,
        'deviceType': deviceType,
        'deviceModel': deviceModel,
        'osVersion': osVersion,
        'appVersion': packageInfo.version,
      };

      print('🔍 Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$url/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _storage.write(key: 'jwt_token', value: data['token']);

          // LoginLogId'yi Session'a kaydet
          if (data['loginLogId'] != null) {
            SessionManager().setLoginLogId(data['loginLogId']);
          }

          return {
            'success': true,
            'token': data['token'],
            'loginLogId': data['loginLogId'],
          };
        }
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'errorMessage': errorData['errorMessage'] ?? 'Giriş başarısız',
      };
    } catch (e) {
      print('🔴 Login Error: $e');
      return {
        'success': false,
        'errorMessage': 'Bağlantı hatası: $e',
      };
    }
  }

  Future<String?> getToken() => _storage.read(key: 'jwt_token');

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUsername() => _storage.read(key: 'username');
  Future<String?> getRole() => _storage.read(key: 'role');

  Future<void> logout() async {
    await _storage.deleteAll();
    SessionManager().clear(); // Session'ı temizle
  }

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
      final loginLogId = await SessionManager().getLoginLogId();

      final response = await http.post(
        Uri.parse('$url/api/sync/full-sync'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'terminalId': terminalId,
          'loginLogId': loginLogId,
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
  }) async {
    try {
      final url = await baseUrl;
      final headers = await _authHeaders();
      final loginLogId = await SessionManager().getLoginLogId();

      final response = await http.post(
        Uri.parse('$url/api/mobiledata/send-mrtc'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'terminalId': terminalId,
          'prosesId': prosesId,
          'username': 'mobile_user',
          'mrtcData': mrtcData,
          'loginLogId': loginLogId,
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
      final loginLogId = await SessionManager().getLoginLogId();

      final response = await http.post(
        Uri.parse('$url/api/stock/seri-ambar-bakiye'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'subeKodu': subeKodu,
          'filter': filter,
          'username': username ?? '',
          'terminalId': terminalId ?? '',
          'loginLogId': loginLogId,
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
      final loginLogId = await SessionManager().getLoginLogId();

      final response = await http.post(
        Uri.parse('$url/api/stock/seri-detay'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'subeKodu': subeKodu,
          'seriNo': seriNo,
          'username': username ?? '',
          'terminalId': terminalId ?? '',
          'loginLogId': loginLogId,
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
      final loginLogId = await SessionManager().getLoginLogId();

      final response = await http.post(
        Uri.parse('$url/api/mobiledata/resend-last'),
        headers: headers,
        body: jsonEncode({
          'companyCode': companyCode,
          'subeKodu': subeKodu,
          'terminalId': terminalId,
          'username': username ?? '',
          'loginLogId': loginLogId,
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
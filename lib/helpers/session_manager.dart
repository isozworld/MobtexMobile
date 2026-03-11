import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final _storage = const FlutterSecureStorage();
  static const String _loginLogIdKey = 'login_log_id';

  int? _loginLogId;

  // LoginLogId'yi hem memory'de hem storage'da tut
  Future<void> setLoginLogId(int? id) async {
    _loginLogId = id;
    if (id != null) {
      await _storage.write(key: _loginLogIdKey, value: id.toString());
    } else {
      await _storage.delete(key: _loginLogIdKey);
    }
  }

  // LoginLogId'yi oku - önce memory'den, yoksa storage'dan
  Future<int?> getLoginLogId() async {
    if (_loginLogId != null) {
      return _loginLogId;
    }

    // Memory'de yoksa storage'dan oku
    final stored = await _storage.read(key: _loginLogIdKey);
    if (stored != null) {
      _loginLogId = int.tryParse(stored);
    }

    return _loginLogId;
  }

  // Synchronous getter (mevcut kullanım için)
  int? get loginLogId => _loginLogId;

  // Uygulama başlatıldığında çağrılacak
  Future<void> initialize() async {
    final stored = await _storage.read(key: _loginLogIdKey);
    if (stored != null) {
      _loginLogId = int.tryParse(stored);
    }
  }

  // Logout'ta temizle
  Future<void> clear() async {
    _loginLogId = null;
    await _storage.delete(key: _loginLogIdKey);
  }
}
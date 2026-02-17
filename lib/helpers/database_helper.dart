import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mobtex.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Şirket ayarları tablosu
    await db.execute('''
      CREATE TABLE company_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_code TEXT NOT NULL,
        company_name TEXT,
        last_sync TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Sync log tablosu
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_type TEXT NOT NULL,
        status TEXT NOT NULL,
        message TEXT,
        synced_at TEXT NOT NULL
      )
    ''');
  }

  // ─── Şirket Ayarları ───────────────────────────────

  Future<Map<String, dynamic>?> getCompanySettings() async {
    final db = await database;
    final result = await db.query('company_settings', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> saveCompanySettings(String companyCode, {String? companyName}) async {
    final db = await database;
    final existing = await getCompanySettings();
    final now = DateTime.now().toIso8601String();

    if (existing != null) {
      return db.update(
        'company_settings',
        {
          'company_code': companyCode,
          'company_name': companyName ?? existing['company_name'],
          'last_sync': now,
        },
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    } else {
      return db.insert('company_settings', {
        'company_code': companyCode,
        'company_name': companyName,
        'last_sync': now,
        'created_at': now,
      });
    }
  }

  Future<int> updateLastSync() async {
    final db = await database;
    final existing = await getCompanySettings();
    if (existing == null) return 0;
    return db.update(
      'company_settings',
      {'last_sync': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [existing['id']],
    );
  }

  // ─── Sync Log ──────────────────────────────────────

  Future<int> addSyncLog(String syncType, String status, {String? message}) async {
    final db = await database;
    return db.insert('sync_log', {
      'sync_type': syncType,
      'status': status,
      'message': message,
      'synced_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncLogs({int limit = 10}) async {
    final db = await database;
    return db.query(
      'sync_log',
      orderBy: 'synced_at DESC',
      limit: limit,
    );
  }
}

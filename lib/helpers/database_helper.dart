import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

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
    return openDatabase(path, version: 6, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }


  Future<void> _onCreate(Database db, int version) async {
    // Settings tables
    await db.execute('''CREATE TABLE app_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT NOT NULL UNIQUE,
      value TEXT,
      updated_at TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE company_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      company_code TEXT NOT NULL,
      company_name TEXT,
      isletme_kodu INTEGER,
      sube_kodu INTEGER,
      fiyat_tipi TEXT,
      last_sync TEXT,
      created_at TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE sync_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sync_type TEXT NOT NULL,
      status TEXT NOT NULL,
      message TEXT,
      synced_at TEXT NOT NULL
    )''');

    // Data tables
    await db.execute('''CREATE TABLE isletmeler (
      ISLETME_KODU INTEGER PRIMARY KEY,
      ADI TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE subeler (
      SUBE_KODU INTEGER PRIMARY KEY,
      ISLETME_KODU INTEGER NOT NULL,
      UNVAN TEXT NOT NULL,
      MERKEZMI TEXT
    )''');

    await db.execute('''CREATE TABLE cariler (
      CARI_KOD TEXT PRIMARY KEY,
      CARI_ISIM TEXT NOT NULL,
      SUBE_KODU INTEGER
    )''');

    await db.execute('''CREATE TABLE plasiyerler (
      PLASIYER_KODU TEXT PRIMARY KEY,
      PLASIYER_ACIKLAMA TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE depolar (
      DEPO_KODU INTEGER PRIMARY KEY,
      DEPO_ISMI TEXT NOT NULL,
      SUBE_KODU INTEGER
    )''');

    await db.execute('''CREATE TABLE ozelkod1 (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      OZELKOD TEXT NOT NULL,
      ACIKLAMA TEXT NOT NULL,
      ISLETME_KODU INTEGER NOT NULL
    )''');

    await db.execute('''CREATE TABLE ozelkod2 (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      OZELKOD TEXT NOT NULL,
      ACIKLAMA TEXT NOT NULL,
      ISLETME_KODU INTEGER NOT NULL
    )''');

    await db.execute('''CREATE TABLE fiyat_tipleri (
      TIPKODU TEXT PRIMARY KEY,
      TIPACIK TEXT NOT NULL
    )''');
    await db.execute('''
  CREATE TABLE mrtc (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    BK TEXT,
    CN TEXT,
    TN TEXT,
    DT INTEGER,
    DP INTEGER,
    D2 INTEGER,
    MK TEXT,
    PK TEXT,
    TI TEXT,
    PI INTEGER,
    SB INTEGER,
    HS INTEGER,
    IL INTEGER,
    HI INTEGER,
    O1 TEXT,
    O2 TEXT,
    BR REAL,
    DV REAL,
    PR REAL,
    MT REAL,
    FT TEXT,
    EKI1 INTEGER,
    EKI2 INTEGER,
    EKI3 INTEGER,
    EKF1 REAL,
    EKF2 REAL,
    EKF3 REAL,
    EKS1 TEXT,
    EKS2 TEXT,
    EKS3 TEXT,
    FL INTEGER
  )
''');
  }

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
  }
  if (oldVersion < 5) {
    // v4: Sync tabloları
    await db.execute('CREATE TABLE IF NOT EXISTS isletmeler (ISLETME_KODU INTEGER PRIMARY KEY, ADI TEXT)');
    await db.execute('CREATE TABLE IF NOT EXISTS subeler (SUBE_KODU INTEGER, ISLETME_KODU INTEGER, UNVAN TEXT, MERKEZMI TEXT, PRIMARY KEY (SUBE_KODU, ISLETME_KODU))');
    await db.execute('CREATE TABLE IF NOT EXISTS cariler (CARI_KOD TEXT PRIMARY KEY, CARI_ISIM TEXT, SUBE_KODU INTEGER)');
    await db.execute('CREATE TABLE IF NOT EXISTS plasiyerler (PLASIYER_KODU TEXT PRIMARY KEY, PLASIYER_ACIKLAMA TEXT)');
    await db.execute('CREATE TABLE IF NOT EXISTS depolar (DEPO_KODU INTEGER, DEPO_ISMI TEXT, SUBE_KODU INTEGER, PRIMARY KEY (DEPO_KODU, SUBE_KODU))');
    await db.execute('CREATE TABLE IF NOT EXISTS ozelkod1 (OZELKOD TEXT, ACIKLAMA TEXT, ISLETME_KODU INTEGER, PRIMARY KEY (OZELKOD, ISLETME_KODU))');
    await db.execute('CREATE TABLE IF NOT EXISTS ozelkod2 (OZELKOD TEXT, ACIKLAMA TEXT, ISLETME_KODU INTEGER, PRIMARY KEY (OZELKOD, ISLETME_KODU))');
    await db.execute('CREATE TABLE IF NOT EXISTS fiyat_tipleri (TIPKODU TEXT PRIMARY KEY, TIPACIK TEXT)');
  }
  if (oldVersion < 6) {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS mrtc (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      BK TEXT, CN TEXT, TN TEXT, DT INTEGER, DP INTEGER,
      D2 INTEGER, MK TEXT, PK TEXT, TI TEXT, PI INTEGER,
      SB INTEGER, HS INTEGER, IL INTEGER, HI INTEGER,
      O1 TEXT, O2 TEXT, BR REAL, DV REAL, PR REAL, MT REAL,
      FT TEXT, EKI1 INTEGER, EKI2 INTEGER, EKI3 INTEGER,
      EKF1 REAL, EKF2 REAL, EKF3 REAL,
      EKS1 TEXT, EKS2 TEXT, EKS3 TEXT, FL INTEGER
    )
  ''');
  }
}

  // ─── APP SETTINGS ──────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value, 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── SERVER URL ────────────────────────────────────────

  static const String _serverUrlKey = 'server_url';
  static const String defaultServerUrl = 'http://10.1.20.55:8282';

  Future<String> getServerUrl() async {
    final url = await getSetting(_serverUrlKey);
    return url ?? defaultServerUrl;
  }

  Future<void> saveServerUrl(String url) async {
    await saveSetting(_serverUrlKey, url.trimRight().replaceAll(RegExp(r'/$'), ''));
  }

  Future<bool> isServerUrlSet() async {
    final url = await getSetting(_serverUrlKey);
    return url != null && url.isNotEmpty;
  }

  // ─── TERMINAL ID ───────────────────────────────────────

  static const String _terminalIdKey = 'terminal_id';

  Future<String?> getTerminalId() async => await getSetting(_terminalIdKey);

  Future<void> saveTerminalId(String terminalId) async {
    await saveSetting(_terminalIdKey, terminalId);
  }

  static List<String> get terminalIdOptions {
    final nums = List.generate(10, (i) => '$i');
    final chars = List.generate(26, (i) => String.fromCharCode(97 + i));
    return [...nums, ...chars];
  }

  // ─── COMPANY SETTINGS ──────────────────────────────────

  Future<Map<String, dynamic>?> getCompanySettings() async {
    final db = await database;
    final result = await db.query('company_settings', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> saveCompanySettings({
    required String companyCode,
    String? companyName,
    int? isletmeKodu,
    int? subeKodu,
    String? fiyatTipi,
  }) async {
    final db = await database;
    final existing = await getCompanySettings();
    final now = DateTime.now().toIso8601String();

    if (existing != null) {
      return db.update(
        'company_settings',
        {
          'company_code': companyCode,
          'company_name': companyName ?? existing['company_name'],
          'isletme_kodu': isletmeKodu ?? existing['isletme_kodu'],
          'sube_kodu': subeKodu ?? existing['sube_kodu'],
          'fiyat_tipi': fiyatTipi ?? existing['fiyat_tipi'],
          'last_sync': now,
        },
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    } else {
      return db.insert('company_settings', {
        'company_code': companyCode,
        'company_name': companyName,
        'isletme_kodu': isletmeKodu,
        'sube_kodu': subeKodu,
        'fiyat_tipi': fiyatTipi,
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

  // ─── SYNC LOG ──────────────────────────────────────────

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
    return db.query('sync_log', orderBy: 'synced_at DESC', limit: limit);
  }

  // ─── SYNC DATA METHODS ─────────────────────────────────

  Future<void> clearAllSyncData() async {
    final db = await database;
    await db.delete('isletmeler');
    await db.delete('subeler');
    await db.delete('cariler');
    await db.delete('plasiyerler');
    await db.delete('depolar');
    await db.delete('ozelkod1');
    await db.delete('ozelkod2');
    await db.delete('fiyat_tipleri');
  }

  Future<void> insertIsletmeler(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    for (var item in data) {
      batch.insert('isletmeler', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertSubeler(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    for (var item in data) {
      batch.insert('subeler', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertCariler(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    for (var item in data) {
      batch.insert('cariler', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertPlasiyerler(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    for (var item in data) {
      batch.insert('plasiyerler', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertDepolar(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    for (var item in data) {
      batch.insert('depolar', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertOzelKod1(List<Map<String, dynamic>> data) async {
    final db = await database;
    await db.delete('ozelkod1'); // Clear first
    final batch = db.batch();
    for (var item in data) {
      batch.insert('ozelkod1', item);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertOzelKod2(List<Map<String, dynamic>> data) async {
    final db = await database;
    await db.delete('ozelkod2'); // Clear first
    final batch = db.batch();
    for (var item in data) {
      batch.insert('ozelkod2', item);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertFiyatTipleri(List<Map<String, dynamic>> data) async {
    final db = await database;
    final batch = db.batch();
    for (var item in data) {
      batch.insert('fiyat_tipleri', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ─── QUERY METHODS ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> getIsletmeler() async {
    final db = await database;
    return await db.query('isletmeler', orderBy: 'ADI');
  }

  Future<List<Map<String, dynamic>>> getSubelerByIsletme(int isletmeKodu) async {
    final db = await database;
    return await db.query(
      'subeler',
      where: 'ISLETME_KODU = ?',
      whereArgs: [isletmeKodu],
      orderBy: 'UNVAN',
    );
  }

  Future<List<Map<String, dynamic>>> getFiyatTipleri() async {
    final db = await database;
    return await db.query('fiyat_tipleri', orderBy: 'TIPACIK');
  }
// MRTc kayıt ekleme
  Future<int> insertMrtc(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('mrtc', data);
  }

// Barkod ile kayıt silme
  Future<int> deleteMrtcByBarcode(String barcode, int prosesId) async {
    final db = await database;
    return await db.delete('mrtc', where: 'BK = ? AND PI = ?', whereArgs: [barcode, prosesId]);
  }

// Proses ID'ye göre tüm kayıtları silme
  Future<int> deleteAllMrtcByProses(int prosesId) async {
    final db = await database;
    return await db.delete('mrtc', where: 'PI = ?', whereArgs: [prosesId]);
  }

// Proses ID'ye göre kayıtları getirme
  Future<List<Map<String, dynamic>>> getMrtcByProses(int prosesId) async {
    final db = await database;
    return await db.query('mrtc', where: 'PI = ?', whereArgs: [prosesId], orderBy: 'ID DESC');
  }

// Barkod sayısı ve çuval sayısı
  Future<Map<String, int>> getMrtcStats(int prosesId) async {
    final db = await database;
    final records = await db.query('mrtc', where: 'PI = ?', whereArgs: [prosesId]);

    final barcodeCount = records.length;
    final cuvalSet = <String>{};
    for (var rec in records) {
      if (rec['CN'] != null && rec['CN'].toString().isNotEmpty) {
        cuvalSet.add(rec['CN'].toString());
      }
    }

    return {'barcodeCount': barcodeCount, 'cuvalCount': cuvalSet.length};
  }

// Barkod kontrolü
  Future<bool> isBarcodeExists(String barcode, int prosesId) async {
    final db = await database;
    final result = await db.query('mrtc', where: 'BK = ? AND PI = ?', whereArgs: [barcode, prosesId]);
    return result.isNotEmpty;
  }

// Cariler getirme (arama ile)
  Future<List<Map<String, dynamic>>> searchCariler(String query) async {
    final db = await database;
    return await db.query(
      'cariler',
      where: 'CARI_KOD LIKE ? OR CARI_ISIM LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 50,
    );
  }

// Depolar getirme (şubeye göre)
  Future<List<Map<String, dynamic>>> getDepolarBySube(int subeKodu) async {
    final db = await database;
    return await db.query('depolar', where: 'SUBE_KODU = ?', whereArgs: [subeKodu], orderBy: 'DEPO_KODU');
  }
// Özel Kod 1 getirme (distinct)
  Future<List<Map<String, dynamic>>> getOzelKod1() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT DISTINCT OZELKOD, ACIKLAMA 
    FROM ozelkod1 
    ORDER BY OZELKOD
  ''');
  }

// Özel Kod 2 getirme (distinct)
  Future<List<Map<String, dynamic>>> getOzelKod2() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT DISTINCT OZELKOD, ACIKLAMA 
    FROM ozelkod2 
    ORDER BY OZELKOD
  ''');
  }
// Barkod miktarını güncelleme (Perakende için)
  Future<int> updateMrtcMiktar(String barcode, int prosesId, double miktar) async {
    final db = await database;
    return await db.update(
      'mrtc',
      {'MT': miktar},
      where: 'BK = ? AND PI = ?',
      whereArgs: [barcode, prosesId],
    );
  }
// Proses ID'lere göre gruplu istatistikler
  Future<List<Map<String, dynamic>>> getMrtcProsesList() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      PI as prosesId,
      COUNT(*) as barcodeCount,
      COUNT(DISTINCT CN) as cuvalCount,
      SUM(CASE WHEN MT IS NOT NULL THEN MT ELSE 0 END) as totalMiktar,
      MIN(MK) as sampleCariKod
    FROM mrtc
    GROUP BY PI
    ORDER BY PI
  ''');
  }

// Proses ID'ye göre detaylı liste (cari bilgisiyle)
  Future<List<Map<String, dynamic>>> getMrtcDetailsByProses(int prosesId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      m.ID,
      m.BK as barkod,
      m.MK as cariKod,
      c.CARI_ISIM as cariIsim,
      m.DP as depoKodu,
      m.SB as subeKodu,
      m.IL as isletmeKodu,
      m.CN as cuvalNo,
      m.TN as tirNo,
      m.MT as miktar,
      m.FT as fiyatTipi
    FROM mrtc m
    LEFT JOIN cariler c ON m.MK = c.CARI_KOD
    WHERE m.PI = ?
    ORDER BY m.ID DESC
  ''', [prosesId]);
  }

// Tüm MRTc kayıtlarını silme
  Future<int> deleteAllMrtc() async {
    final db = await database;
    return await db.delete('mrtc');
  }
  // Toptan satış son seçimleri kaydetme
  Future<void> saveToptanSatisSelections({
    required String cariKod,
    required String cariText,
    required int depoKodu,
    required int dovizTipi,
    required String ozelKod1,
    required String ozelKod2,
    required String fiyatTipi,
    required String plasiyerKod,
    required String plasiyerText,
  }) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': 'toptan_satis_selections',
        'value': jsonEncode({
          'cariKod': cariKod,
          'cariText': cariText,
          'depoKodu': depoKodu,
          'dovizTipi': dovizTipi,
          'ozelKod1': ozelKod1,
          'ozelKod2': ozelKod2,
          'fiyatTipi': fiyatTipi,
          'plasiyerKod': plasiyerKod,
          'plasiyerText': plasiyerText,
        }),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Toptan satış son seçimleri getirme
  Future<Map<String, dynamic>?> getToptanSatisSelections() async {
    final db = await database;
    final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['toptan_satis_selections']);
    if (result.isEmpty) return null;

    final value = result.first['value'] as String;
    return jsonDecode(value) as Map<String, dynamic>;
  }

// Perakende satış son seçimleri kaydetme
  Future<void> savePerakendeSatisSelections({
    required String cariKod,
    required String cariText,
    required int depoKodu,
    required int dovizTipi,
    required String ozelKod1,
    required String ozelKod2,
    required String fiyatTipi,
    required String plasiyerKod,
    required String plasiyerText,
  }) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': 'perakende_satis_selections',
        'value': jsonEncode({
          'cariKod': cariKod,
          'cariText': cariText,
          'depoKodu': depoKodu,
          'dovizTipi': dovizTipi,
          'ozelKod1': ozelKod1,
          'ozelKod2': ozelKod2,
          'fiyatTipi': fiyatTipi,
          'plasiyerKod': plasiyerKod,
          'plasiyerText': plasiyerText,
        }),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Perakende satış son seçimleri getirme
  Future<Map<String, dynamic>?> getPerakendeSatisSelections() async {
    final db = await database;
    final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['perakende_satis_selections']);
    if (result.isEmpty) return null;

    final value = result.first['value'] as String;
    return jsonDecode(value) as Map<String, dynamic>;
  }

// Depolar Arası Transfer seçimleri kaydetme
  Future<void> saveDepolarArasiTransferSelections({
    required int hedefSubeKodu,
    required int kaynakDepoKodu,
    required int hedefDepoKodu,
  }) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': 'depolar_arasi_transfer_selections',
        'value': jsonEncode({
          'hedefSubeKodu': hedefSubeKodu,
          'kaynakDepoKodu': kaynakDepoKodu,
          'hedefDepoKodu': hedefDepoKodu,
        }),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Depolar Arası Transfer seçimleri getirme
  Future<Map<String, dynamic>?> getDepolarArasiTransferSelections() async {
    final db = await database;
    final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['depolar_arasi_transfer_selections']);
    if (result.isEmpty) return null;

    final value = result.first['value'] as String;
    return jsonDecode(value) as Map<String, dynamic>;
  }

// Arabadan Transfer seçimleri kaydetme
  Future<void> saveArabadanTransferSelections({
    required int kaynakDepoKodu,
    required int hedefDepoKodu,
  }) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': 'arabadan_transfer_selections',
        'value': jsonEncode({
          'kaynakDepoKodu': kaynakDepoKodu,
          'hedefDepoKodu': hedefDepoKodu,
        }),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Arabadan Transfer seçimleri getirme
  Future<Map<String, dynamic>?> getArabadanTransferSelections() async {
    final db = await database;
    final result = await db.query('app_settings', where: 'key = ?', whereArgs: ['arabadan_transfer_selections']);
    if (result.isEmpty) return null;

    final value = result.first['value'] as String;
    return jsonDecode(value) as Map<String, dynamic>;
  }

// Tüm plasiyerleri getir
  Future<List<Map<String, dynamic>>> getPlasiyerler() async {
    final db = await database;
    return await db.query('plasiyerler', orderBy: 'PLASIYER_KODU');
  }


// Plasiyer arama
  Future<List<Map<String, dynamic>>> searchPlasiyerler(String query) async {
    final db = await database;
    final queryUpper = query.toUpperCase();

    print('Plasiyer aranıyor: $queryUpper'); // ← DEBUG

    final results = await db.rawQuery('''
    SELECT * FROM plasiyerler
    WHERE UPPER(PLASIYER_KODU) LIKE ? OR UPPER(PLASIYER_ACIKLAMA) LIKE ?
    ORDER BY PLASIYER_KODU
    LIMIT 20
  ''', ['%$queryUpper%', '%$queryUpper%']);

    print('Bulunan plasiyer: ${results.length}'); // ← DEBUG

    return results;
  }
// Test metodu ekleyin
  Future<void> testPlasiyerler() async {
    final db = await database;
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM plasiyerler');
    print('Plasiyerler tablosunda kayıt sayısı: $count');

    final sample = await db.query('plasiyerler', limit: 5);
    print('İlk 5 plasiyer: $sample');
  }
}

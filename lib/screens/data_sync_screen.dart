import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/services/api_service.dart';

class DataSyncScreen extends StatefulWidget {
  const DataSyncScreen({super.key});

  @override
  State<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<DataSyncScreen> {
  final _companyCodeController = TextEditingController();
  final _urlController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  final _apiService = ApiService();

  bool _isSaving = false;
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String? _syncStatus;
  String? _lastSync;
  String? _selectedTerminalId;
  List<Map<String, dynamic>> _syncLogs = [];

  final List<String> _terminalOptions = DatabaseHelper.terminalIdOptions;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _companyCodeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final settings = await _dbHelper.getCompanySettings();
    final url = await _dbHelper.getServerUrl();
    final terminalId = await _dbHelper.getTerminalId();
    final logs = await _dbHelper.getSyncLogs();
    setState(() {
      if (settings != null) {
        _companyCodeController.text = settings['company_code'] ?? '';
        _lastSync = settings['last_sync'];
      }
      _urlController.text = url;
      _selectedTerminalId = terminalId ?? _terminalOptions.first;
      _syncLogs = logs;
    });
  }

  Future<void> _saveAll() async {
    final code = _companyCodeController.text.trim();
    final url = _urlController.text.trim();

    if (code.isEmpty) {
      _showSnack('Sirket kodu bos birakilamaz', isError: true);
      return;
    }
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      _showSnack('Gecerli bir URL giriniz (http:// ile baslamali)', isError: true);
      return;
    }
    if (_selectedTerminalId == null) {
      _showSnack('Terminal ID secmelisiniz', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    await _dbHelper.saveCompanySettings(companyCode: code);
    await _dbHelper.saveServerUrl(url);
    await _dbHelper.saveTerminalId(_selectedTerminalId!);
    await _dbHelper.addSyncLog('Ayar Kayit', 'Basarili',
        message: 'Sirket: $code | Terminal: $_selectedTerminalId | URL: $url');
    setState(() => _isSaving = false);
    await _loadData();
    _showSnack('Bilgiler kaydedildi');
  }

  Future<void> _syncAllData() async {
    final code = _companyCodeController.text.trim();
    if (code.isEmpty || _selectedTerminalId == null) {
      _showSnack('Once sirket kodu ve terminal ID kaydedin', isError: true);
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _syncStatus = 'Baglanti kuruluyor...';
    });

    try {
      final result = await _apiService.syncAllData(code, _selectedTerminalId!);

      if (result['success']) {
        final data = result['data'];

        setState(() {
          _syncStatus = 'Veriler indiriliyor...';
          _syncProgress = 0.2;
        });
        await Future.delayed(const Duration(milliseconds: 300));

        // İşletmeler
        if (data['isletmeler'] != null) {
          await _dbHelper.insertIsletmeler(
            List<Map<String, dynamic>>.from(data['isletmeler'].map((e) => {
                  'ISLETME_KODU': e['isletmE_KODU'] ?? e['ISLETME_KODU'],
                  'ADI': e['adi'] ?? e['ADI'] ?? '',
                })),
          );
        }
        setState(() {
          _syncProgress = 0.3;
          _syncStatus = 'Isletmeler kaydedildi';
        });
        await Future.delayed(const Duration(milliseconds: 200));

        // Şubeler
        if (data['subeler'] != null) {
          await _dbHelper.insertSubeler(
            List<Map<String, dynamic>>.from(data['subeler'].map((e) => {
                  'SUBE_KODU': e['subE_KODU'] ?? e['SUBE_KODU'],
                  'ISLETME_KODU': e['isletmE_KODU'] ?? e['ISLETME_KODU'],
                  'UNVAN': e['unvan'] ?? e['UNVAN'] ?? '',
                  'MERKEZMI': e['merkezmi'] ?? e['MERKEZMI'] ?? 'H',
                })),
          );
        }
        setState(() {
          _syncProgress = 0.4;
          _syncStatus = 'Subeler kaydedildi';
        });
        await Future.delayed(const Duration(milliseconds: 200));

        // Cariler
        if (data['cariler'] != null) {
          await _dbHelper.insertCariler(
            List<Map<String, dynamic>>.from(data['cariler'].map((e) => {
                  'CARI_KOD': e['carI_KOD'] ?? e['CARI_KOD'] ?? '',
                  'CARI_ISIM': e['carI_ISIM'] ?? e['CARI_ISIM'] ?? '',
                  'SUBE_KODU': e['subE_KODU'] ?? e['SUBE_KODU'] ?? 0,
                })),
          );
        }
        setState(() {
          _syncProgress = 0.55;
          _syncStatus = 'Cariler kaydedildi';
        });
        await Future.delayed(const Duration(milliseconds: 200));


// Plasiyerler
        if (data['plasiyerler'] != null) {
          print('===== PLASIYER SYNC DEBUG =====');
          print('API\'den gelen plasiyerler sayısı: ${data['plasiyerler'].length}');

          // İlk 3 kaydı göster
          if (data['plasiyerler'].length > 0) {
            print('İlk kayıt RAW: ${data['plasiyerler'][0]}');
          }

          final plasiyerlerList = List<Map<String, dynamic>>.from(
              data['plasiyerler'].map((e) {
                final mapped = {
                  'PLASIYER_KODU': e['plasiyeR_KODU'] ?? '',
                  'PLASIYER_ACIKLAMA': e['plasiyeR_ACIKLAMA'] ?? '',
                };
                return mapped;
              })
          );

          print('Dönüştürülmüş plasiyerler sayısı: ${plasiyerlerList.length}');
          if (plasiyerlerList.isNotEmpty) {
            print('İlk dönüştürülmüş kayıt: ${plasiyerlerList[0]}');
          }

          await _dbHelper.insertPlasiyerler(plasiyerlerList);

          // Kaydedildikten sonra kontrol
          final savedCount = await _dbHelper.getPlasiyerler();
          print('Veritabanına kaydedilen plasiyer sayısı: ${savedCount.length}');
          if (savedCount.isNotEmpty) {
            print('Veritabanından ilk kayıt: ${savedCount[0]}');
          }
          print('===============================');
        }
        setState(() {
          _syncProgress = 0.65;
          _syncStatus = 'Plasiyerler kaydedildi';
        });
        await Future.delayed(const Duration(milliseconds: 200));

        // Depolar
        if (data['depolar'] != null) {
          await _dbHelper.insertDepolar(
            List<Map<String, dynamic>>.from(data['depolar'].map((e) => {
                  'DEPO_KODU': e['depO_KODU'] ?? e['DEPO_KODU'],
                  'DEPO_ISMI': e['depO_ISMI'] ?? e['DEPO_ISMI'] ?? '',
                  'SUBE_KODU': e['subE_KODU'] ?? e['SUBE_KODU'] ?? 0,
                })),
          );
        }
        setState(() {
          _syncProgress = 0.75;
          _syncStatus = 'Depolar kaydedildi';
        });
        await Future.delayed(const Duration(milliseconds: 200));

        // Özel Kodlar
        if (data['ozelKod1'] != null) {
          await _dbHelper.insertOzelKod1(
            List<Map<String, dynamic>>.from(data['ozelKod1'].map((e) => {
                  'OZELKOD': e['ozelkod'] ?? e['OZELKOD'] ?? '',
                  'ACIKLAMA': e['aciklama'] ?? e['ACIKLAMA'] ?? '',
                  'ISLETME_KODU': e['isletmE_KODU'] ?? e['ISLETME_KODU'],
                })),
          );
        }
        if (data['ozelKod2'] != null) {
          await _dbHelper.insertOzelKod2(
            List<Map<String, dynamic>>.from(data['ozelKod2'].map((e) => {
                  'OZELKOD': e['ozelkod'] ?? e['OZELKOD'] ?? '',
                  'ACIKLAMA': e['aciklama'] ?? e['ACIKLAMA'] ?? '',
                  'ISLETME_KODU': e['isletmE_KODU'] ?? e['ISLETME_KODU'],
                })),
          );
        }
        setState(() {
          _syncProgress = 0.85;
          _syncStatus = 'Ozel kodlar kaydedildi';
        });
        await Future.delayed(const Duration(milliseconds: 200));

        // Fiyat Tipleri
        if (data['fiyatTipleri'] != null) {
          await _dbHelper.insertFiyatTipleri(
            List<Map<String, dynamic>>.from(data['fiyatTipleri'].map((e) => {
                  'TIPKODU': e['tipkodu'] ?? e['TIPKODU'] ?? '',
                  'TIPACIK': e['tipacik'] ?? e['TIPACIK'] ?? '',
                })),
          );
        }
        setState(() {
          _syncProgress = 1.0;
          _syncStatus = 'Tamamlandi!';
        });

        await _dbHelper.updateLastSync();
        await _dbHelper.addSyncLog('Tam Eslestirme', 'Basarili',
            message:
                '${data['recordCounts']?['Isletmeler'] ?? 0} isletme, ${data['recordCounts']?['Subeler'] ?? 0} sube, ${data['recordCounts']?['Cariler'] ?? 0} cari kaydedildi');
        await Future.delayed(const Duration(milliseconds: 800));
        _showSnack('Tum veriler basariyla esitlendi');
      } else {
        await _dbHelper.addSyncLog('Tam Eslestirme', 'Hata', message: result['message']);
        _showSnack(result['message'] ?? 'Eslestirme hatasi', isError: true);
      }
    } catch (e) {
      await _dbHelper.addSyncLog('Tam Eslestirme', 'Hata', message: e.toString());
      _showSnack('Hata: $e', isError: true);
    }

    setState(() {
      _isSyncing = false;
      _syncStatus = null;
    });
    await _loadData();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF8b5cf6),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
              title: const Text('Veri Senkronizasyon',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8b5cf6), Color(0xFF6d28d9)],
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                    right: -30, top: -30,
                    child: Container(width: 150, height: 150,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08))),
                  ),
                  Positioned(
                    right: 30, bottom: 20,
                    child: Icon(Icons.sync_rounded, size: 80, color: Colors.white.withOpacity(0.15)),
                  ),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_lastSync != null) ...[_buildLastSyncCard(), const SizedBox(height: 16)],
                  _buildSettingsCard(),
                  const SizedBox(height: 20),
                  _buildSyncButton(),
                  const SizedBox(height: 28),
                  if (_syncLogs.isNotEmpty) ...[
                    _buildSectionTitle('Eslestirme Gecmisi'),
                    const SizedBox(height: 12),
                    _buildSyncLogs(),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSyncCard() {
    final syncDate = DateTime.tryParse(_lastSync!);
    final formatted = syncDate != null
        ? '${syncDate.day.toString().padLeft(2, '0')}.${syncDate.month.toString().padLeft(2, '0')}.${syncDate.year}  ${syncDate.hour.toString().padLeft(2, '0')}:${syncDate.minute.toString().padLeft(2, '0')}'
        : '-';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8b5cf6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8b5cf6).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF8b5cf6), size: 18),
        const SizedBox(width: 10),
        Text('Son eslestirme: $formatted',
            style: const TextStyle(color: Color(0xFF6d28d9), fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF8b5cf6).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.tune_rounded, color: Color(0xFF8b5cf6), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Baglanti Ayarlari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: _companyCodeController,
            decoration: _inputDec('Sirket Kodu', Icons.business_rounded, hint: 'Sirket kodunuzu girin', color: const Color(0xFF8b5cf6)),
          ),
          const SizedBox(height: 14),
          _dividerRow('Sunucu'),
          const SizedBox(height: 14),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: _inputDec('Servis API URL', Icons.link_rounded, hint: 'http://10.1.20.55:8282', color: const Color(0xFF667eea)).copyWith(
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF667eea)),
                tooltip: 'Varsayilana sifirla',
                onPressed: () => setState(() => _urlController.text = DatabaseHelper.defaultServerUrl),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedTerminalId,
            decoration: InputDecoration(
              labelText: 'Terminal ID',
              prefixIcon: const Icon(Icons.phonelink_rounded, color: Color(0xFF10b981)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF10b981), width: 2)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _terminalOptions.map((val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Center(
                      child: Text(val.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10b981))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(int.tryParse(val) != null ? 'Terminal $val' : 'Terminal ${val.toUpperCase()}', style: const TextStyle(fontSize: 14)),
                ]),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedTerminalId = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAll,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8b5cf6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerRow(String label) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.grey[200])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
      Expanded(child: Divider(color: Colors.grey[200])),
    ]);
  }

  InputDecoration _inputDec(String label, IconData icon, {String? hint, required Color color}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: color),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _buildSyncButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        boxShadow: [BoxShadow(color: const Color(0xFF667eea).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSyncing ? null : _syncAllData,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: _isSyncing
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.sync_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_isSyncing ? _syncStatus ?? 'Esitleniyor...' : 'Tum Verileri Esitle ve Kaydet',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_isSyncing ? 'Lutfen bekleyin...' : 'Sunucudan tum veriler cekilir ve kaydedilir',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ]),
                  ),
                  if (!_isSyncing) Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.8), size: 16),
                ]),
                if (_isSyncing) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _syncProgress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${(_syncProgress * 100).toInt()}%', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                    Text(_syncStatus ?? '', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [
      Container(width: 4, height: 24, decoration: BoxDecoration(color: const Color(0xFF8b5cf6), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
    ]);
  }

  Widget _buildSyncLogs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _syncLogs.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final log = _syncLogs[index];
          final isSuccess = log['status'] == 'Basarili';
          final date = DateTime.tryParse(log['synced_at'] ?? '');
          final formatted = date != null
              ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
              : '-';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: (isSuccess ? const Color(0xFF10b981) : Colors.red).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(isSuccess ? Icons.check_rounded : Icons.error_rounded,
                    color: isSuccess ? const Color(0xFF10b981) : Colors.red, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(log['sync_type'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1e293b))),
                  if (log['message'] != null) Text(log['message'], style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ]),
              ),
              Text(formatted, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          );
        },
      ),
    );
  }
}

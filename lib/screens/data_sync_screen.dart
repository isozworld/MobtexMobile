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
  final _dbHelper = DatabaseHelper.instance;
  final _apiService = ApiService();

  bool _isSaving = false;
  bool _isSyncing = false;
  String? _lastSync;
  List<Map<String, dynamic>> _syncLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _companyCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final settings = await _dbHelper.getCompanySettings();
    final logs = await _dbHelper.getSyncLogs();
    setState(() {
      if (settings != null) {
        _companyCodeController.text = settings['company_code'] ?? '';
        _lastSync = settings['last_sync'];
      }
      _syncLogs = logs;
    });
  }

  Future<void> _saveCompanyCode() async {
    final code = _companyCodeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Şirket kodu boş bırakılamaz', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    await _dbHelper.saveCompanySettings(code);
    await _dbHelper.addSyncLog('Şirket Kayıt', 'Başarılı',
        message: 'Şirket kodu kaydedildi: $code');

    setState(() => _isSaving = false);
    await _loadData();
    _showSnack('Şirket kodu başarıyla kaydedildi');
  }

  Future<void> _syncAllData() async {
    final code = _companyCodeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Önce şirket kodunu kaydedin', isError: true);
      return;
    }

    setState(() => _isSyncing = true);

    final result = await _apiService.syncAllData();

    if (result['success']) {
      await _dbHelper.updateLastSync();
      await _dbHelper.addSyncLog('Tam Eşitleme', 'Başarılı',
          message: 'Tüm veriler eşitlendi');
      _showSnack('Tüm veriler başarıyla eşitlendi ✓');
    } else {
      await _dbHelper.addSyncLog('Tam Eşitleme', 'Hata',
          message: result['message']);
      _showSnack(result['message'] ?? 'Eşitleme hatası', isError: true);
    }

    setState(() => _isSyncing = false);
    await _loadData();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Color(0xFF10b981),
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
          // AppBar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF8b5cf6),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Veri Senkronizasyon',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8b5cf6), Color(0xFF6d28d9)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: 20,
                      child: Icon(
                        Icons.sync_rounded,
                        size: 80,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Son sync bilgisi
                  if (_lastSync != null) _buildLastSyncCard(),
                  if (_lastSync != null) const SizedBox(height: 16),

                  // Şirket kodu kartı
                  _buildCompanyCodeCard(),
                  const SizedBox(height: 20),

                  // Sync butonu
                  _buildSyncButton(),
                  const SizedBox(height: 28),

                  // Sync log
                  if (_syncLogs.isNotEmpty) ...[
                    _buildSectionTitle('Eşitleme Geçmişi'),
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
    final syncDate = _lastSync != null
        ? DateTime.tryParse(_lastSync!)
        : null;
    final formatted = syncDate != null
        ? '${syncDate.day.toString().padLeft(2, '0')}.${syncDate.month.toString().padLeft(2, '0')}.${syncDate.year} ${syncDate.hour.toString().padLeft(2, '0')}:${syncDate.minute.toString().padLeft(2, '0')}'
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF8b5cf6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFF8b5cf6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF8b5cf6), size: 20),
          const SizedBox(width: 10),
          Text(
            'Son eşitleme: $formatted',
            style: TextStyle(
              color: Color(0xFF6d28d9),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF8b5cf6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.business_rounded,
                    color: Color(0xFF8b5cf6), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Şirket Bilgisi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // TextBox
          TextField(
            controller: _companyCodeController,
            decoration: InputDecoration(
              labelText: 'Şirket Kodu',
              hintText: 'Şirket kodunuzu girin',
              prefixIcon: Icon(Icons.tag_rounded, color: Color(0xFF8b5cf6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF8b5cf6), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 14),

          // Kaydet butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveCompanyCode,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                _isSaving ? 'Kaydediliyor...' : 'Kaydet',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8b5cf6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSyncing ? null : _syncAllData,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isSyncing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded,
                          color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSyncing ? 'Eşitleniyor...' : 'Tüm Verileri Eşitle ve Kaydet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sunucudan tüm veriler çekilir ve kaydedilir',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isSyncing)
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.8), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Color(0xFF8b5cf6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncLogs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _syncLogs.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final log = _syncLogs[index];
          final isSuccess = log['status'] == 'Başarılı';
          final date = DateTime.tryParse(log['synced_at'] ?? '');
          final formatted = date != null
              ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
              : '-';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isSuccess ? Color(0xFF10b981) : Colors.red)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_rounded : Icons.error_rounded,
                    color: isSuccess ? Color(0xFF10b981) : Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['sync_type'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      if (log['message'] != null)
                        Text(
                          log['message'],
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Text(
                  formatted,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

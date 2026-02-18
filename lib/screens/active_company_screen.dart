import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';

class ActiveCompanyScreen extends StatefulWidget {
  const ActiveCompanyScreen({super.key});

  @override
  State<ActiveCompanyScreen> createState() => _ActiveCompanyScreenState();
}

class _ActiveCompanyScreenState extends State<ActiveCompanyScreen> {
  final _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _companySettings;
  String? _serverUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _isletmeler = [];
  List<Map<String, dynamic>> _subeler = [];
  List<Map<String, dynamic>> _fiyatTipleri = [];

  int? _selectedIsletme;
  int? _selectedSube;
  String? _selectedFiyatTipi;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _companySettings = await _dbHelper.getCompanySettings();
    _serverUrl = await _dbHelper.getServerUrl();
    _isletmeler = await _dbHelper.getIsletmeler();
    _fiyatTipleri = await _dbHelper.getFiyatTipleri();

    if (_companySettings != null) {
      _selectedIsletme = _companySettings!['isletme_kodu'] as int?;
      _selectedSube = _companySettings!['sube_kodu'] as int?;
      _selectedFiyatTipi = _companySettings!['fiyat_tipi'] as String?;

      if (_selectedIsletme != null) {
        _subeler = await _dbHelper.getSubelerByIsletme(_selectedIsletme!);
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _onIsletmeChanged(int? value) async {
    setState(() {
      _selectedIsletme = value;
      _selectedSube = null;
      _subeler = [];
    });

    if (value != null) {
      final subeler = await _dbHelper.getSubelerByIsletme(value);
      setState(() => _subeler = subeler);
    }
  }

  Future<void> _save() async {
    if (_selectedIsletme == null) {
      _showSnack('Lutfen bir isletme secin', isError: true);
      return;
    }
    if (_selectedSube == null) {
      _showSnack('Lutfen bir sube secin', isError: true);
      return;
    }
    if (_selectedFiyatTipi == null) {
      _showSnack('Lutfen bir fiyat tipi secin', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    await _dbHelper.saveCompanySettings(
      companyCode: _companySettings?['company_code'] ?? '',
      isletmeKodu: _selectedIsletme,
      subeKodu: _selectedSube,
      fiyatTipi: _selectedFiyatTipi,
    );

    setState(() => _isSaving = false);
    _showSnack('Ayarlar kaydedildi');
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
            backgroundColor: const Color(0xFF0ea5e9),
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
              title: const Text('Aktif Sirket Bilgileri',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)],
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
                    child: Icon(Icons.business_rounded, size: 80, color: Colors.white.withOpacity(0.15)),
                  ),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
                : _companySettings == null
                    ? _buildEmptyState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
            child: Icon(Icons.business_outlined, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text('Henuz sirket tanimlanmamis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('Ayarlar > Veri Sync ekranından sirket bilgilerini tanimlayiniz',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildSelectionCard(),
          const SizedBox(height: 20),
          _buildServerCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final syncDate = _companySettings!['last_sync'] != null ? DateTime.tryParse(_companySettings!['last_sync']) : null;
    final formatted = syncDate != null
        ? '${syncDate.day.toString().padLeft(2, '0')}.${syncDate.month.toString().padLeft(2, '0')}.${syncDate.year}  ${syncDate.hour.toString().padLeft(2, '0')}:${syncDate.minute.toString().padLeft(2, '0')}'
        : 'Henuz sync edilmedi';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0ea5e9).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_companySettings!['company_code'] ?? 'Bilinmiyor',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Sirket Kodu', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text(formatted, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildSelectionCard() {
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
             decoration: BoxDecoration(color: const Color(0xFF0ea5e9).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
             child: const Icon(Icons.settings_rounded, color: Color(0xFF0ea5e9), size: 22),
           ),
           const SizedBox(width: 12),
           const Text('Calisma Ayarlari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
         ]),
         const SizedBox(height: 20),

         // İşletme
         Text('Isletme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
         const SizedBox(height: 8),
         DropdownButtonFormField<int>(
           value: _selectedIsletme,
           decoration: _inputDec('Isletme Seciniz', Icons.domain_rounded),
           isExpanded: true,
           items: _isletmeler.map((item) {
             final kod = item['ISLETME_KODU'] as int;
             final adi = item['ADI'] as String;
             return DropdownMenuItem<int>(
               value: kod,
               child: Text('$kod - $adi', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
             );
           }).toList(),
           selectedItemBuilder: (context) {
             return _isletmeler.map((item) {
               final kod = item['ISLETME_KODU'] as int;
               final adi = item['ADI'] as String;
               return Text('$kod - $adi', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis);
             }).toList();
           },
           onChanged: _onIsletmeChanged,
         ),
         const SizedBox(height: 16),

         // Şube
         Text('Sube', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
         const SizedBox(height: 8),
         DropdownButtonFormField<int>(
           value: _selectedSube,
           decoration: _inputDec('Sube Seciniz', Icons.store_rounded),
           isExpanded: true,
           items: _subeler.map((item) {
             final kod = item['SUBE_KODU'] as int;
             final unvan = item['UNVAN'] as String;
             return DropdownMenuItem<int>(
               value: kod,
               child: Text('$kod - $unvan', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
             );
           }).toList(),
           selectedItemBuilder: (context) {
             return _subeler.map((item) {
               final kod = item['SUBE_KODU'] as int;
               final unvan = item['UNVAN'] as String;
               return Text('$kod - $unvan', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis);
             }).toList();
           },
           onChanged: (v) => setState(() => _selectedSube = v),
         ),
         const SizedBox(height: 16),

         // Fiyat Tipi
         Text('Fiyat Tipi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
         const SizedBox(height: 8),
         DropdownButtonFormField<String>(
           value: _selectedFiyatTipi,
           decoration: _inputDec('Fiyat Tipi Seciniz', Icons.attach_money_rounded),
           isExpanded: true,
           items: _fiyatTipleri.map((item) {
             final kod = item['TIPKODU'] as String;
             final acik = item['TIPACIK'] as String;
             return DropdownMenuItem<String>(
               value: kod,
               child: Text('$kod - $acik', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
             );
           }).toList(),
           selectedItemBuilder: (context) {
             return _fiyatTipleri.map((item) {
               final kod = item['TIPKODU'] as String;
               final acik = item['TIPACIK'] as String;
               return Text('$kod - $acik', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis);
             }).toList();
           },
           onChanged: (v) => setState(() => _selectedFiyatTipi = v),
         ),
         const SizedBox(height: 20),

         // Kaydet butonu
         SizedBox(
           width: double.infinity,
           child: ElevatedButton.icon(
             onPressed: _isSaving ? null : _save,
             icon: _isSaving
                 ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                 : const Icon(Icons.save_rounded, size: 20),
             label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
             style: ElevatedButton.styleFrom(
               backgroundColor: const Color(0xFF0ea5e9),
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

  Widget _buildServerCard() {
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
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.cloud_rounded, color: Colors.grey[700], size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Baglanti Detaylari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
          ]),
          const SizedBox(height: 16),
          _buildInfoRow('Sunucu URL', _serverUrl ?? 'Bilinmiyor', Icons.dns_rounded),
          _buildInfoRow('Veritabani', 'mobtex.db (SQLite)', Icons.storage_rounded),
          _buildInfoRow('Terminal ID', _companySettings!['terminal_id']?.toString() ?? '-', Icons.phonelink_rounded),
          _buildInfoRow('Durum', 'Bagli', Icons.check_circle_rounded, valueColor: const Color(0xFF10b981)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text('$label:', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF1e293b)),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF0ea5e9)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder:
          const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF0ea5e9), width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
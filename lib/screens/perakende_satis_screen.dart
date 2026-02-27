import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/screens/barcode_scan_screen.dart';

class PerakendeSatisScreen extends StatefulWidget {
  const PerakendeSatisScreen({super.key});

  @override
  State<PerakendeSatisScreen> createState() => _PerakendeSatisScreenState();
}

class _PerakendeSatisScreenState extends State<PerakendeSatisScreen> {
  final _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _companySettings;
  String? _terminalId;
  bool _isLoading = true;

  List<Map<String, dynamic>> _cariler = [];
  List<Map<String, dynamic>> _depolar = [];
  List<Map<String, dynamic>> _ozelKod1 = [];
  List<Map<String, dynamic>> _ozelKod2 = [];
  List<Map<String, dynamic>> _fiyatTipleri = [];
  List<Map<String, dynamic>> _plasiyerler = [];

  String? _selectedCari;
  int? _selectedDepo;
  int? _selectedDoviz;
  String? _selectedOzelKod1;
  String? _selectedOzelKod2;
  String? _selectedFiyatTipi;
  String? _selectedPlasiyer;

  final _plasiyerController = TextEditingController();
  bool _isSearchingPlasiyer = false;

  final _cariController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cariController.dispose();
    _plasiyerController.dispose();
    super.dispose();
  }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _companySettings = await _dbHelper.getCompanySettings();
    _terminalId = await _dbHelper.getTerminalId();
    _ozelKod1 = await _dbHelper.getOzelKod1();
    _ozelKod2 = await _dbHelper.getOzelKod2();
    _fiyatTipleri = await _dbHelper.getFiyatTipleri();
    _plasiyerler = await _dbHelper.getPlasiyerler();

    if (_companySettings != null) {
      final subeKodu = _companySettings!['sube_kodu'] as int?;
      if (subeKodu != null) {
        _depolar = await _dbHelper.getDepolarBySube(subeKodu);
      }
    }

    // Son seçimleri yükle ve validasyon yap
    final lastSelections = await _dbHelper.getPerakendeSatisSelections();
    if (lastSelections != null) {
      // Cari
      _selectedCari = lastSelections['cariKod'] as String?;
      _cariController.text = lastSelections['cariText'] as String? ?? '';

      // Depo - listede var mı kontrol et
      final depoKodu = lastSelections['depoKodu'] as int?;
      if (depoKodu != null && _depolar.any((d) => d['DEPO_KODU'] == depoKodu)) {
        _selectedDepo = depoKodu;
      }

      // Döviz tipi - 0, 1, 2 aralığında mı kontrol et
      final dovizTipi = lastSelections['dovizTipi'] as int?;
      if (dovizTipi != null && dovizTipi >= 0 && dovizTipi <= 2) {
        _selectedDoviz = dovizTipi;
      }

      // Özel kod 1 - listede var mı kontrol et
      final ozelKod1 = lastSelections['ozelKod1'] as String?;
      if (ozelKod1 != null && _ozelKod1.any((o) => o['OZELKOD'] == ozelKod1)) {
        _selectedOzelKod1 = ozelKod1;
      }

      // Özel kod 2 - listede var mı kontrol et
      final ozelKod2 = lastSelections['ozelKod2'] as String?;
      if (ozelKod2 != null && _ozelKod2.any((o) => o['OZELKOD'] == ozelKod2)) {
        _selectedOzelKod2 = ozelKod2;
      }

      // Fiyat tipi - listede var mı kontrol et
      final fiyatTipi = lastSelections['fiyatTipi'] as String?;
      if (fiyatTipi != null && _fiyatTipleri.any((f) => f['TIPKODU'] == fiyatTipi)) {
        _selectedFiyatTipi = fiyatTipi;
      }

      // Plasiyer
      _selectedPlasiyer = lastSelections['plasiyerKod'] as String?;
      _plasiyerController.text = lastSelections['plasiyerText'] as String? ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _searchPlasiyer(String query) async {
    if (query.isEmpty) {
      setState(() {
        _plasiyerler = [];
        _isSearchingPlasiyer = false;
      });
      return;
    }

    setState(() => _isSearchingPlasiyer = true);

    try {
      final results = await _dbHelper.searchPlasiyerler(query);
      print('Plasiyer arama sonucu: ${results.length} kayıt bulundu'); // ← DEBUG

      if (mounted) {
        setState(() {
          _plasiyerler = results;
          _isSearchingPlasiyer = false;
        });
      }
    } catch (e) {
      print('Plasiyer arama hatası: $e'); // ← DEBUG
      if (mounted) {
        setState(() {
          _plasiyerler = [];
          _isSearchingPlasiyer = false;
        });
      }
    }
  }


  void _selectPlasiyer(Map<String, dynamic> plasiyer) {
    setState(() {
      _selectedPlasiyer = plasiyer['PLASIYER_KODU'] as String;
      _plasiyerController.text = '${plasiyer['PLASIYER_KODU']} - ${plasiyer['PLASIYER_ACIKLAMA']}';
      _plasiyerler = [];
    });
  }
  Future<void> _searchCari(String query) async {
    if (query.isEmpty) {
      setState(() {
        _cariler = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _dbHelper.searchCariler(query);
    setState(() {
      _cariler = results;
      _isSearching = false;
    });
  }

  void _selectCari(Map<String, dynamic> cari) {
    setState(() {
      _selectedCari = cari['CARI_KOD'] as String;
      _cariController.text = '${cari['CARI_KOD']} - ${cari['CARI_ISIM']}';
      _cariler = [];
    });
  }

  void _navigateToBarcodeScan() {
    if (_selectedCari == null) {
      _showSnack('Lutfen musteri secin', isError: true);
      return;
    }
    if (_selectedDepo == null) {
      _showSnack('Lutfen depo secin', isError: true);
      return;
    }
    if (_selectedDoviz == null) {
      _showSnack('Lutfen doviz tipi secin', isError: true);
      return;
    }
    if (_selectedOzelKod1 == null) {
      _showSnack('Lutfen Ozel Kod 1 secin', isError: true);
      return;
    }
    if (_selectedOzelKod2 == null) {
      _showSnack('Lutfen Ozel Kod 2 secin', isError: true);
      return;
    }
    if (_selectedFiyatTipi == null) {
      _showSnack('Lutfen fiyat tipi secin', isError: true);
      return;
    }
    if (_selectedPlasiyer == null) {
      _showSnack('Lutfen plasiyer secin', isError: true);
      return;
    }
    // Seçimleri kaydet
    _dbHelper.savePerakendeSatisSelections(
      cariKod: _selectedCari!,
      cariText: _cariController.text,
      depoKodu: _selectedDepo!,
      dovizTipi: _selectedDoviz!,
      ozelKod1: _selectedOzelKod1!,
      ozelKod2: _selectedOzelKod2!,
      fiyatTipi: _selectedFiyatTipi!,
      plasiyerKod: _selectedPlasiyer ?? '',
      plasiyerText: _plasiyerController.text,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanScreen(
          prosesId: 1,
          prosesAdi: 'Perakende Satış',
          terminalId: _terminalId ?? '',
          subeKodu: _companySettings!['sube_kodu'] as int,
          isletmeKodu: _companySettings!['isletme_kodu'] as int,
          depoKodu: _selectedDepo!,
          cariKod: _selectedCari!,
          plasiyerKod: _selectedPlasiyer ?? '',
          dovizTipi: _selectedDoviz!,
          ozelKod1: _selectedOzelKod1!,
          ozelKod2: _selectedOzelKod2!,
          fiyatTipi: _selectedFiyatTipi!,
          showMiktar: true,
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF667eea),
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
              title: const Text('Perakende Satış',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10b981), Color(0xFF667eea)],
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                    right: -40, top: -40,
                    child: Container(width: 180, height: 180,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08))),
                  ),
                  Positioned(
                    right: 50, top: 40,
                    child: Container(width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08))),
                  ),
                  Positioned(
                    right: 30, bottom: 20,
                    child: Icon(Icons.shopping_cart_rounded, size: 90, color: Colors.white.withOpacity(0.15)),
                  ),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 20),
          _buildFormCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3b82f6), Color(0xFF2563eb)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: const Color(0xFF3b82f6).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('İşlem: Toptan Satış (PI: 0)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Terminal: ${_terminalId ?? '-'} | Şube: ${_companySettings?['sube_kodu'] ?? '-'}',
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10b981), size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Satış Bilgileri', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
            ],
          ),
          const SizedBox(height: 24),

// Müşteri Arama
          Text('Müşteri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextField(
            controller: _cariController,
            decoration: InputDecoration(
              hintText: 'Müşteri kodu veya ismi ile ara...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF10b981)),
              suffixIcon: _isSearching
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : (_cariController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _cariController.clear();
                    _selectedCari = null;
                  });
                  _searchCari('');
                },
              )
                  : null),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF10b981), width: 2)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: _searchCari,
          ),
          if (_cariler.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _cariler.length,
                itemBuilder: (context, index) {
                  final cari = _cariler[index];
                  return ListTile(
                    dense: true,
                    title: Text('${cari['CARI_KOD']} - ${cari['CARI_ISIM']}', style: const TextStyle(fontSize: 14)),
                    onTap: () => _selectCari(cari),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Depo
          Text('Depo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          // Depo Dropdown
          DropdownButtonFormField<int>(
            value: _selectedDepo != null && _depolar.any((d) => d['DEPO_KODU'] == _selectedDepo)
                ? _selectedDepo
                : null,
            decoration: _inputDec('Depo Seçiniz', Icons.warehouse_rounded),
            isExpanded: true,
            items: _depolar.map((item) {
              final kod = item['DEPO_KODU'] as int;
              final isim = item['DEPO_ISMI'] as String;
              return DropdownMenuItem<int>(value: kod, child: Text('$kod - $isim', overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) => setState(() => _selectedDepo = v),
          ),
          const SizedBox(height: 16),

          // Döviz Tipi
          Text('Döviz Tipi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          // Döviz Tipi Dropdown
          DropdownButtonFormField<int>(
            value: _selectedDoviz != null && _selectedDoviz! >= 0 && _selectedDoviz! <= 2
                ? _selectedDoviz
                : null,
            decoration: _inputDec('Döviz Tipi', Icons.currency_exchange_rounded),
            items: const [
              DropdownMenuItem(value: 0, child: Text('TL')),
              DropdownMenuItem(value: 1, child: Text('USD')),
              DropdownMenuItem(value: 2, child: Text('EUR')),
            ],
            onChanged: (v) => setState(() => _selectedDoviz = v),
          ),
          const SizedBox(height: 16),

          // Özel Kod 1
          Text('Özel Kod 1', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          // Özel Kod 1 Dropdown
          DropdownButtonFormField<String>(
            value: _selectedOzelKod1 != null && _ozelKod1.any((o) => o['OZELKOD'] == _selectedOzelKod1)
                ? _selectedOzelKod1
                : null,
            decoration: _inputDec('Özel Kod 1', Icons.label_outline),
            isExpanded: true,
            items: _ozelKod1.map((item) {
              final kod = item['OZELKOD'] as String;
              final aciklama = item['ACIKLAMA'] as String;
              return DropdownMenuItem<String>(value: kod, child: Text('$kod - $aciklama', overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) => setState(() => _selectedOzelKod1 = v),
          ),
          const SizedBox(height: 16),

          // Özel Kod 2
          Text('Özel Kod 2', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          // Özel Kod 2 Dropdown
          DropdownButtonFormField<String>(
            value: _selectedOzelKod2 != null && _ozelKod2.any((o) => o['OZELKOD'] == _selectedOzelKod2)
                ? _selectedOzelKod2
                : null,
            decoration: _inputDec('Özel Kod 2', Icons.label),
            isExpanded: true,
            items: _ozelKod2.map((item) {
              final kod = item['OZELKOD'] as String;
              final aciklama = item['ACIKLAMA'] as String;
              return DropdownMenuItem<String>(value: kod, child: Text('$kod - $aciklama', overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) => setState(() => _selectedOzelKod2 = v),
          ),
          const SizedBox(height: 16),

          // Fiyat Tipi
          Text('Fiyat Tipi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          // Fiyat Tipi Dropdown
          DropdownButtonFormField<String>(
            value: _selectedFiyatTipi != null && _fiyatTipleri.any((f) => f['TIPKODU'] == _selectedFiyatTipi)
                ? _selectedFiyatTipi
                : null,
            decoration: _inputDec('Fiyat Tipi Seçiniz', Icons.price_check_rounded),
            isExpanded: true,
            items: _fiyatTipleri.map((item) {
              final kod = item['TIPKODU'] as String;
              final acik = item['TIPACIK'] as String;
              return DropdownMenuItem<String>(value: kod, child: Text('$kod - $acik', overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) => setState(() => _selectedFiyatTipi = v),
          ),
          const SizedBox(height: 28),

// Plasiyer Arama (YENİ)
          Text('Plasiyer (Opsiyonel)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextField(
            controller: _plasiyerController,
            decoration: InputDecoration(
              hintText: 'Plasiyer kodu veya ismi ile ara...',
              prefixIcon: const Icon(Icons.person_search, color: Color(0xFF10b981)),
              suffixIcon: _isSearchingPlasiyer
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : (_plasiyerController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _plasiyerController.clear();
                    _selectedPlasiyer = null;
                  });
                  _searchPlasiyer('');
                },
              )
                  : null),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF10b981), width: 2)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: _searchPlasiyer,
          ),
          if (_plasiyerler.isNotEmpty && _plasiyerController.text.isNotEmpty && _selectedPlasiyer == null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _plasiyerler.length,
                itemBuilder: (context, index) {
                  final plasiyer = _plasiyerler[index];
                  return ListTile(
                    dense: true,
                    title: Text('${plasiyer['PLASIYER_KODU']} - ${plasiyer['PLASIYER_ACIKLAMA']}',
                        style: const TextStyle(fontSize: 14)),
                    onTap: () => _selectPlasiyer(plasiyer),
                  );
                },
              ),
            ),
          const SizedBox(height: 28),


          // Barkod Okutma Butonu
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _navigateToBarcodeScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 30),
              label: const Text('Barkod Okutmaya Başla', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFF10b981).withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF10b981)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF10b981), width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/screens/barcode_scan_screen.dart';

class DepolarArasiTransferScreen extends StatefulWidget {
  const DepolarArasiTransferScreen({super.key});

  @override
  State<DepolarArasiTransferScreen> createState() => _DepolarArasiTransferScreenState();
}

class _DepolarArasiTransferScreenState extends State<DepolarArasiTransferScreen> {
  final _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _companySettings;
  String? _terminalId;
  bool _isLoading = true;

  List<Map<String, dynamic>> _hedefSubeler = [];
  List<Map<String, dynamic>> _kaynakDepolar = [];
  List<Map<String, dynamic>> _hedefDepolar = [];

  int? _selectedHedefSube;
  int? _selectedKaynakDepo;
  int? _selectedHedefDepo;

  String _kaynakSubeAdi = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _companySettings = await _dbHelper.getCompanySettings();
    _terminalId = await _dbHelper.getTerminalId();

    if (_companySettings != null) {
      final aktifSubeKodu = _companySettings!['sube_kodu'] as int?;
      final aktifIsletmeKodu = _companySettings!['isletme_kodu'] as int?;

      if (aktifSubeKodu != null && aktifIsletmeKodu != null) {
        // Aktif şubenin adını al
        final db = await _dbHelper.database;
        final subeResult = await db.query('subeler', where: 'SUBE_KODU = ?', whereArgs: [aktifSubeKodu]);
        if (subeResult.isNotEmpty) {
          _kaynakSubeAdi = subeResult.first['UNVAN'] as String? ?? 'Şube $aktifSubeKodu';
        }

        // Hedef şubeleri getir (aynı işletme, farklı şube)
        _hedefSubeler = await db.rawQuery('''
          SELECT SUBE_KODU, UNVAN 
          FROM subeler 
          WHERE ISLETME_KODU = ? AND SUBE_KODU != ?
          ORDER BY UNVAN
        ''', [aktifIsletmeKodu, aktifSubeKodu]);

        // Kaynak depoları getir (kendi şubemizin depoları)
        _kaynakDepolar = await _dbHelper.getDepolarBySube(aktifSubeKodu);
      }
    }

    // Son seçimleri yükle
    final lastSelections = await _dbHelper.getDepolarArasiTransferSelections();
    if (lastSelections != null) {
      setState(() {
        _selectedHedefSube = lastSelections['hedefSubeKodu'] as int?;
        _selectedKaynakDepo = lastSelections['kaynakDepoKodu'] as int?;
        _selectedHedefDepo = lastSelections['hedefDepoKodu'] as int?;
      });

      // Hedef şube seçiliyse, hedef depoları yükle
      if (_selectedHedefSube != null) {
        await _loadHedefDepolar(_selectedHedefSube!);
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadHedefDepolar(int hedefSubeKodu) async {
    final depolar = await _dbHelper.getDepolarBySube(hedefSubeKodu);
    setState(() {
      _hedefDepolar = depolar;
      // Eğer seçili hedef depo artık listede yoksa temizle
      if (_selectedHedefDepo != null && !depolar.any((d) => d['DEPO_KODU'] == _selectedHedefDepo)) {
        _selectedHedefDepo = null;
      }
    });
  }

  void _navigateToBarcodeScan() {
    if (_selectedHedefSube == null) {
      _showSnack('Lütfen hedef şube seçin', isError: true);
      return;
    }
    if (_selectedKaynakDepo == null) {
      _showSnack('Lütfen kaynak depo seçin', isError: true);
      return;
    }
    if (_selectedHedefDepo == null) {
      _showSnack('Lütfen hedef depo seçin', isError: true);
      return;
    }

    // Seçimleri kaydet
    _dbHelper.saveDepolarArasiTransferSelections(
      hedefSubeKodu: _selectedHedefSube!,
      kaynakDepoKodu: _selectedKaynakDepo!,
      hedefDepoKodu: _selectedHedefDepo!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanScreen(
          prosesId: 3,
          prosesAdi: 'Depolar Arası Transfer',
          terminalId: _terminalId ?? '',
          subeKodu: _companySettings!['sube_kodu'] as int,
          isletmeKodu: _companySettings!['isletme_kodu'] as int,
          depoKodu: _selectedKaynakDepo!,
          hedefSubeKodu: _selectedHedefSube!,
          hedefDepoKodu: _selectedHedefDepo!,
          cariKod: '',
          plasiyerKod: '',
          dovizTipi: 0,
          ozelKod1: '',
          ozelKod2: '',
          fiyatTipi: '',
          showMiktar: false,
          showCuvalTir: false,
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFFf59e0b),
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
            backgroundColor: const Color(0xFFf59e0b),
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
              title: const Text('Depolar Arası Transfer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
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
                    child: Icon(Icons.swap_horiz_rounded, size: 90, color: Colors.white.withOpacity(0.15)),
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
                const Text('İşlem: Depolar Arası Transfer (PI: 3)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Terminal: ${_terminalId ?? '-'}',
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
                  color: const Color(0xFFf59e0b).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFf59e0b), size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Transfer Bilgileri', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
            ],
          ),
          const SizedBox(height: 24),

          // Hedef Şube
          Text('Hedef Şube', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedHedefSube,
            decoration: _inputDec('Hedef Şube Seçiniz', Icons.store_rounded),
            isExpanded: true,
            items: _hedefSubeler.map((item) {
              final kod = item['SUBE_KODU'] as int;
              final unvan = item['UNVAN'] as String;
              return DropdownMenuItem<int>(value: kod, child: Text('$kod - $unvan', overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) {
              setState(() {
                _selectedHedefSube = v;
                _selectedHedefDepo = null;
                _hedefDepolar = [];
              });
              if (v != null) {
                _loadHedefDepolar(v);
              }
            },
          ),
          const SizedBox(height: 16),

          // Hedef Depo (Hedef Şube seçiliyse göster)
          if (_selectedHedefSube != null) ...[
            Text('Hedef Depo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedHedefDepo,
              decoration: _inputDec('Hedef Depo Seçiniz', Icons.warehouse_rounded),
              isExpanded: true,
              items: _hedefDepolar.map((item) {
                final kod = item['DEPO_KODU'] as int;
                final isim = item['DEPO_ISMI'] as String;
                return DropdownMenuItem<int>(value: kod, child: Text('$kod - $isim', overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (v) => setState(() => _selectedHedefDepo = v),
            ),
            const SizedBox(height: 16),
          ],

          // Kaynak Şube (Sadece bilgi)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kaynak Şube: $_kaynakSubeAdi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kaynak Depo
          Text('Kaynak Depo (Kendi Şubemiz)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedKaynakDepo,
            decoration: _inputDec('Kaynak Depo Seçiniz', Icons.warehouse_rounded),
            isExpanded: true,
            items: _kaynakDepolar.map((item) {
              final kod = item['DEPO_KODU'] as int;
              final isim = item['DEPO_ISMI'] as String;
              return DropdownMenuItem<int>(value: kod, child: Text('$kod - $isim', overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) => setState(() => _selectedKaynakDepo = v),
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
                backgroundColor: const Color(0xFFf59e0b),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFFf59e0b).withOpacity(0.4),
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
      prefixIcon: Icon(icon, color: const Color(0xFFf59e0b)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFf59e0b), width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
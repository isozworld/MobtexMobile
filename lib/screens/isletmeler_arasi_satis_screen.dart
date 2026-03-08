import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/screens/barcode_scan_screen.dart';

class IsletmelerArasiSatisScreen extends StatefulWidget {
  const IsletmelerArasiSatisScreen({super.key});

  @override
  State<IsletmelerArasiSatisScreen> createState() => _IsletmelerArasiSatisScreenState();
}

class _IsletmelerArasiSatisScreenState extends State<IsletmelerArasiSatisScreen> {
  final _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic>? _companySettings;
  String? _terminalId;
  bool _isLoading = true;

  List<Map<String, dynamic>> _hedefIsletmeler = [];
  List<Map<String, dynamic>> _hedefSubeler = [];
  List<Map<String, dynamic>> _hedefDepolar = [];
  List<Map<String, dynamic>> _kaynakDepolar = [];

  int? _selectedHedefIsletme;
  int? _selectedHedefSube;
  int? _selectedHedefDepo;
  int? _selectedKaynakDepo;

  String _kaynakSubeAdi = '';
  int _aktifSubeKodu = 0;
  int _aktifIsletmeKodu = 0;

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
      _aktifSubeKodu = _companySettings!['sube_kodu'] as int? ?? 0;
      _aktifIsletmeKodu = _companySettings!['isletme_kodu'] as int? ?? 0;

      // Kaynak şube adını al
      final subeResult = await _dbHelper.rawQuery(
        'SELECT UNVAN FROM subeler WHERE SUBE_KODU = ?',
        [_aktifSubeKodu],
      );
      if (subeResult.isNotEmpty) {
        _kaynakSubeAdi = subeResult.first['UNVAN'] as String? ?? 'Şube $_aktifSubeKodu';
      }

      // Kaynak depolar - aktif şubeye ait
      _kaynakDepolar = await _dbHelper.getDepolarBySube(_aktifSubeKodu);

      // Hedef işletmeler - kendi işletmemiz hariç
      _hedefIsletmeler = await _dbHelper.rawQuery(
        'SELECT ISLETME_KODU, ADI as UNVAN FROM isletmeler WHERE ISLETME_KODU != ? ORDER BY ADI',
        [_aktifIsletmeKodu],
      );
    }

    // Son seçimleri yükle
    final lastSelections = await _dbHelper.getIsletmelerArasiSatisSelections();
    if (lastSelections != null) {
      final hedefIsletme = lastSelections['hedefIsletmeKodu'] as int?;
      final hedefSube = lastSelections['hedefSubeKodu'] as int?;
      final hedefDepo = lastSelections['hedefDepoKodu'] as int?;
      final kaynakDepo = lastSelections['kaynakDepoKodu'] as int?;

      // Hedef işletme listede var mı kontrol et
      if (hedefIsletme != null &&
          _hedefIsletmeler.any((i) => i['ISLETME_KODU'] == hedefIsletme)) {
        _selectedHedefIsletme = hedefIsletme;
        await _loadHedefSubeler(hedefIsletme);

        // Hedef şube listede var mı kontrol et
        if (hedefSube != null &&
            _hedefSubeler.any((s) => s['SUBE_KODU'] == hedefSube)) {
          _selectedHedefSube = hedefSube;
          await _loadHedefDepolar(hedefSube);

          // Hedef depo listede var mı kontrol et
          if (hedefDepo != null &&
              _hedefDepolar.any((d) => d['DEPO_KODU'] == hedefDepo)) {
            _selectedHedefDepo = hedefDepo;
          }
        }
      }

      // Kaynak depo listede var mı kontrol et
      if (kaynakDepo != null &&
          _kaynakDepolar.any((d) => d['DEPO_KODU'] == kaynakDepo)) {
        _selectedKaynakDepo = kaynakDepo;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadHedefSubeler(int isletmeKodu) async {
    final subeler = await _dbHelper.getSubelerByIsletme(isletmeKodu);
    setState(() {
      _hedefSubeler = subeler;
      if (_selectedHedefSube != null &&
          !subeler.any((s) => s['SUBE_KODU'] == _selectedHedefSube)) {
        _selectedHedefSube = null;
        _selectedHedefDepo = null;
        _hedefDepolar = [];
      }
    });
  }

  Future<void> _loadHedefDepolar(int subeKodu) async {
    final depolar = await _dbHelper.getDepolarBySube(subeKodu);
    setState(() {
      _hedefDepolar = depolar;
      if (_selectedHedefDepo != null &&
          !depolar.any((d) => d['DEPO_KODU'] == _selectedHedefDepo)) {
        _selectedHedefDepo = null;
      }
    });
  }

  void _navigateToBarcodeScan() {
    if (_selectedHedefIsletme == null) {
      _showSnack('Lütfen hedef işletme seçin', isError: true);
      return;
    }
    if (_selectedHedefSube == null) {
      _showSnack('Lütfen hedef şube seçin', isError: true);
      return;
    }
    if (_selectedHedefDepo == null) {
      _showSnack('Lütfen hedef depo seçin', isError: true);
      return;
    }
    if (_selectedKaynakDepo == null) {
      _showSnack('Lütfen kaynak depo seçin', isError: true);
      return;
    }

    _dbHelper.saveIsletmelerArasiSatisSelections(
      hedefIsletmeKodu: _selectedHedefIsletme!,
      hedefSubeKodu: _selectedHedefSube!,
      hedefDepoKodu: _selectedHedefDepo!,
      kaynakDepoKodu: _selectedKaynakDepo!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanScreen(
          prosesId: 10,
          prosesAdi: 'İşletmeler Arası Satış',
          terminalId: _terminalId ?? '',
          subeKodu: _aktifSubeKodu,
          isletmeKodu: _aktifIsletmeKodu,
          depoKodu: _selectedKaynakDepo!,
          hedefSubeKodu: _selectedHedefSube!,
          hedefDepoKodu: _selectedHedefDepo!,
          hedefIsletmeKodu: _selectedHedefIsletme!,
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
      appBar: AppBar(
        title: const Text('İşletmeler Arası Satış',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFf59e0b),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: '🏢 Hedef Bilgileri',
              color: const Color(0xFFf59e0b),
              children: [
                _buildComboLabel('Hedef İşletme'),
                _buildDropdown(
                  value: _selectedHedefIsletme,
                  items: _hedefIsletmeler,
                  keyField: 'ISLETME_KODU',
                  labelField: 'UNVAN',
                  hint: 'İşletme seçin...',
                  color: const Color(0xFFf59e0b),
                  onChanged: (val) async {
                    setState(() {
                      _selectedHedefIsletme = val;
                      _selectedHedefSube = null;
                      _selectedHedefDepo = null;
                      _hedefSubeler = [];
                      _hedefDepolar = [];
                    });
                    if (val != null) await _loadHedefSubeler(val);
                  },
                ),
                const SizedBox(height: 16),
                _buildComboLabel('Hedef Şube'),
                _buildDropdown(
                  value: _selectedHedefSube,
                  items: _hedefSubeler,
                  keyField: 'SUBE_KODU',
                  labelField: 'UNVAN',
                  hint: 'Önce işletme seçin...',
                  color: const Color(0xFFf59e0b),
                  onChanged: _hedefSubeler.isEmpty
                      ? null
                      : (val) async {
                    setState(() {
                      _selectedHedefSube = val;
                      _selectedHedefDepo = null;
                      _hedefDepolar = [];
                    });
                    if (val != null) await _loadHedefDepolar(val);
                  },
                ),
                const SizedBox(height: 16),
                _buildComboLabel('Hedef Depo'),
                _buildDropdown(
                  value: _selectedHedefDepo,
                  items: _hedefDepolar,
                  keyField: 'DEPO_KODU',
                  labelField: 'DEPO_ADI',
                  hint: 'Önce şube seçin...',
                  color: const Color(0xFFf59e0b),
                  onChanged: _hedefDepolar.isEmpty
                      ? null
                      : (val) => setState(() => _selectedHedefDepo = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: '📦 Kaynak Bilgileri',
              color: const Color(0xFF3b82f6),
              children: [
                _buildComboLabel('Kaynak Şube'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3b82f6), Color(0xFF2563eb)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _kaynakSubeAdi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Aktif Şube',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildComboLabel('Kaynak Depo'),
                _buildDropdown(
                  value: _selectedKaynakDepo,
                  items: _kaynakDepolar,
                  keyField: 'DEPO_KODU',
                  labelField: 'DEPO_ADI',
                  hint: 'Kaynak depo seçin...',
                  color: const Color(0xFF3b82f6),
                  onChanged: (val) =>
                      setState(() => _selectedKaynakDepo = val),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _navigateToBarcodeScan,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                label: const Text(
                  'Barkod Okutmaya Başla',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf59e0b),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildComboLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569))),
    );
  }

  Widget _buildDropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String keyField,
    required String labelField,
    required String hint,
    required Color color,
    required ValueChanged<int?>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: onChanged == null ? Colors.grey[100] : Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(hint,
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(12),
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item[keyField] as int,
              child: Text(
                '${item[labelField] ?? ''} (${item[keyField]})',
                style: const TextStyle(fontSize: 14, color: Color(0xFF1e293b)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
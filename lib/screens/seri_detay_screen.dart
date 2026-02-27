import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/services/api_service.dart';

class SeriDetayScreen extends StatefulWidget {
  const SeriDetayScreen({super.key});

  @override
  State<SeriDetayScreen> createState() => _SeriDetayScreenState();
}

class _SeriDetayScreenState extends State<SeriDetayScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _apiService = ApiService();
  final _seriController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _seriData;
  Set<String> _expandedSeriler = {};

  @override
  void dispose() {
    _seriController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final seriNo = _seriController.text.trim();

    if (seriNo.isEmpty) {
      _showSnack('Lütfen seri numarası giriniz', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _seriData = null;
    });

    try {
      final companySettings = await _dbHelper.getCompanySettings();
      if (companySettings == null) {
        throw Exception('Şirket bilgileri bulunamadı');
      }

      final companyCode = companySettings['company_code'] as String;
      final subeKodu = companySettings['sube_kodu'] as int;

      final response = await _apiService.getSeriDetay(
        companyCode: companyCode,
        subeKodu: subeKodu,
        seriNo: seriNo,
      );

      if (response['success'] == true) {
        setState(() {
          _seriData = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['errorMessage'] ?? 'Bilinmeyen hata';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  void _openBarcodeScanner() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BarcodeScannerDialog(
        onBarcodeDetected: (barcode) {
          Navigator.pop(context);
          setState(() {
            _seriController.text = barcode;
          });
          _search();
        },
      ),
    );
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Seri Detay', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10b981),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          if (_errorMessage != null) _buildErrorCard(),
          if (_isLoading) _buildLoading(),
          Expanded(
            child: _isLoading
                ? Container()
                : _seriData == null
                ? _buildEmptyState()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2, color: Color(0xFF10b981), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Seri Numarası Sorgula',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _seriController,
                  decoration: InputDecoration(
                    hintText: 'Seri numarası giriniz...',
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10b981)),
                      onPressed: _openBarcodeScanner,
                      tooltip: 'Barkod Okut',
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF10b981), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                ),
              ),
              SizedBox(
                width: 56,
                height: 56,
                child: ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.search, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[900], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF10b981)),
            SizedBox(height: 16),
            Text('Sorgulanıyor...', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Seri detayını görmek için\nseri numarası giriniz',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildContent() {
    final okutulanSeriler = _seriData!['okutulanSeriBilgileri'] as List? ?? [];
    final fiyatlarList = _seriData!['fiyatlar'] as List? ?? []; // Map → List
    final digerSeriler = _seriData!['depodakiDigerSeriler'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Okutulan Seri Bilgileri
          if (okutulanSeriler.isNotEmpty) ...[
            _buildSectionTitle('📦 Okutulan Seri Bilgileri'),
            const SizedBox(height: 12),
            ...okutulanSeriler.map((seri) => _buildSeriCard(seri)),
          ],

          // Fiyat Bilgileri
          if (fiyatlarList.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('💰 Fiyat Bilgileri'),
            const SizedBox(height: 12),
            _buildFiyatCard(fiyatlarList),
          ],

          // Depodaki Diğer Seriler
          if (digerSeriler.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('📍 Depodaki Diğer Seriler (${digerSeriler.length})'),
            const SizedBox(height: 12),
            _buildDigerSerilerCard(digerSeriler),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1e293b),
      ),
    );
  }

  Widget _buildSeriCard(Map<String, dynamic> seri) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10b981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seri No',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      seri['seriNo'] ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.inventory, 'Miktar', '${seri['bakiye'] ?? seri['miktar'] ?? 0}'),
          _buildInfoRow(Icons.location_on, 'Hücre', seri['hucre'] ?? '-'),
          _buildInfoRow(Icons.warehouse, 'Depo', '${seri['depoKodu'] ?? '-'}'),
          _buildInfoRow(Icons.store, 'Şube', '${seri['subeKodu'] ?? '-'}'),
          if (seri['koleksiyon'] != null && seri['koleksiyon'].toString().isNotEmpty)
            _buildInfoRow(Icons.collections_bookmark, 'Koleksiyon', seri['koleksiyon']),
          if (seri['eskiDesen'] != null && seri['eskiDesen'].toString().isNotEmpty)
            _buildInfoRow(Icons.palette, 'Eski Desen', seri['eskiDesen']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiyatCard(List fiyatlarList) {
    return DefaultTabController(
      length: fiyatlarList.length,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFf59e0b).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: TabBar(
                isScrollable: true,
                labelColor: const Color(0xFFf59e0b),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFFf59e0b),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                tabs: fiyatlarList.map((fiyat) {
                  final fiyatTipi = fiyat['fiyatTipi'] ?? 'N/A';
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(fiyatTipi),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Tab Views
            SizedBox(
              height: 360,
              child: TabBarView(
                children: fiyatlarList.map((fiyat) {
                  return _buildFiyatTabContent(fiyat);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiyatTabContent(Map<String, dynamic> fiyat) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
                child: const Icon(Icons.attach_money, color: Color(0xFFf59e0b), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Fiyat Tipi: ${fiyat['fiyatTipi'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFiyatRow('Kar Oranı', '%${fiyat['karOrani'] ?? 0}', Colors.purple),
          _buildFiyatRow('Dolar', '\$${fiyat['dolar'] ?? 0}', Colors.green),
          _buildFiyatRow('Euro', '€${fiyat['euro'] ?? 0}', Colors.orange),
          _buildFiyatRow('TL', '${fiyat['tl'] ?? 0} ₺', Colors.red),
        ],
      ),
    );
  }

  Widget _buildFiyatRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDigerSerilerCard(List digerSeriler) {
    final toplamMiktar = digerSeriler.fold<double>(
      0,
          (sum, seri) => sum + ((seri['bakiye'] ?? 0) as num).toDouble(),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2, color: Color(0xFF3b82f6), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Toplam ${digerSeriler.length} Seri',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3b82f6),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3b82f6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Miktar: ${toplamMiktar.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: digerSeriler.length,
            itemBuilder: (context, index) {
              final seri = digerSeriler[index];
              final isExpanded = _expandedSeriler.contains(seri['seriNo']);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedSeriler.remove(seri['seriNo']);
                    } else {
                      _expandedSeriler.add(seri['seriNo']);
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExpanded ? const Color(0xFF3b82f6).withOpacity(0.05) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isExpanded ? const Color(0xFF3b82f6) : Colors.grey[200]!,
                      width: isExpanded ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3b82f6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code, color: Color(0xFF3b82f6), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  seri['seriNo'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1e293b),
                                  ),
                                ),
                                Text(
                                  'Miktar: ${seri['bakiye'] ?? 0}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF3b82f6),
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _buildDetailItem(Icons.warehouse, 'Depo', '${seri['depoKodu']}'),
                        _buildDetailItem(Icons.store, 'Şube', '${seri['subeKodu']}'),
                        _buildDetailItem(Icons.location_on, 'Hücre', seri['hucre'] ?? 'YERDE'),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1e293b)),
          ),
        ],
      ),
    );
  }
}

// Barkod Scanner Dialog
class _BarcodeScannerDialog extends StatefulWidget {
  final Function(String) onBarcodeDetected;

  const _BarcodeScannerDialog({required this.onBarcodeDetected});

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    var barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.isNotEmpty) {
      // ]C1, ]E0, ]d2 gibi prefix'leri temizle
      if (barcode.startsWith(']')) {
        final match = RegExp(r'^\][A-Za-z0-9]{2}').firstMatch(barcode);
        if (match != null) {
          barcode = barcode.substring(match.end);
        }
      }
      widget.onBarcodeDetected(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: 400,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (_scannerController != null)
              MobileScanner(controller: _scannerController!, onDetect: _onBarcodeDetected),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.black),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30)),
                  child: const Text('Seri numarasını okutun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
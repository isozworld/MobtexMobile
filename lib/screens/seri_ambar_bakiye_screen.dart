import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/services/api_service.dart';

class SeriAmbarBakiyeScreen extends StatefulWidget {
  const SeriAmbarBakiyeScreen({super.key});

  @override
  State<SeriAmbarBakiyeScreen> createState() => _SeriAmbarBakiyeScreenState();
}

class _SeriAmbarBakiyeScreenState extends State<SeriAmbarBakiyeScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _apiService = ApiService();
  final _searchController = TextEditingController();

  List<StokGrup> _stoklar = [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _expandedStoklar = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final filter = _searchController.text.trim();

    if (filter.isEmpty) {
      _showSnack('Lütfen arama kriteri giriniz', isError: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _stoklar = [];
    });

    try {
      final companySettings = await _dbHelper.getCompanySettings();
      if (companySettings == null) {
        throw Exception('Şirket bilgileri bulunamadı');
      }

      final companyCode = companySettings['company_code'] as String;
      final subeKodu = companySettings['sube_kodu'] as int;

      final response = await _apiService.getSeriAmbarBakiye(
        companyCode: companyCode,
        subeKodu: subeKodu,
        filter: filter,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data['stoklar'] != null) {
          setState(() {
            _stoklar = (data['stoklar'] as List)
                .map((e) => StokGrup.fromJson(e))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['errorMessage'] ?? 'Veri bulunamadı';
            _isLoading = false;
          });
        }
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
            _searchController.text = barcode;
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
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF3b82f6),
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
        title: const Text('Seri Ambar Bakiye', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3b82f6),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          if (_errorMessage != null) _buildErrorCard(),
          if (_isLoading) _buildLoading(),
          if (!_isLoading && _stoklar.isNotEmpty) _buildResultInfo(),
          Expanded(
            child: _isLoading
                ? Container()
                : _stoklar.isEmpty
                ? _buildEmptyState()
                : _buildStokList(),
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
                  color: const Color(0xFF3b82f6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search, color: Color(0xFF3b82f6), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Stok veya Seri Ara',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Stok kodu veya seri no giriniz...',
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF3b82f6)),
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
                      borderSide: BorderSide(color: Color(0xFF3b82f6), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3b82f6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 16),
            Text('Aranıyor...', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultInfo() {
    final toplamStok = _stoklar.fold<double>(0, (sum, s) => sum + s.toplamStokMiktar);
    final toplamSeri = _stoklar.fold<int>(0, (sum, s) => sum + s.seriler.length);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3b82f6), Color(0xFF2563eb)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3b82f6).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Stok Grubu', _stoklar.length.toString(), Icons.widgets),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem('Toplam Seri', toplamSeri.toString(), Icons.qr_code_2),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem('Miktar', toplamStok.toStringAsFixed(0), Icons.inventory),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Arama yapmak için stok veya seri giriniz',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStokList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _stoklar.length,
      itemBuilder: (context, index) {
        final stok = _stoklar[index];
        final isExpanded = _expandedStoklar.contains(stok.stokKodu);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.2)),
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
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedStoklar.remove(stok.stokKodu);
                    } else {
                      _expandedStoklar.add(stok.stokKodu);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3b82f6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF3b82f6), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stok.stokKodu,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1e293b),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.warehouse, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Depo: ${stok.depoKodu}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.store, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Şube: ${stok.subeKodu}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF3b82f6),
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3b82f6).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem('Toplam', stok.toplamStokMiktar.toStringAsFixed(0)),
                                ),
                                Expanded(
                                  child: _buildInfoItem('Seri', stok.seriler.length.toString()),
                                ),
                              ],
                            ),
                            if (stok.koleksiyon != null && stok.koleksiyon!.isNotEmpty ||
                                stok.eskiDesen != null && stok.eskiDesen!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (stok.koleksiyon != null && stok.koleksiyon!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[50],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.purple[200]!),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.collections_bookmark, size: 12, color: Colors.purple[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            stok.koleksiyon!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.purple[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (stok.eskiDesen != null && stok.eskiDesen!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.orange[200]!),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.palette_outlined, size: 12, color: Colors.orange[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            stok.eskiDesen!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange[900],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) _buildSeriList(stok),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3b82f6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSeriList(StokGrup stok) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withOpacity(0.1),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2, size: 16, color: Color(0xFF3b82f6)),
                const SizedBox(width: 8),
                Text(
                  'Seri Detayları (${stok.seriler.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3b82f6),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stok.seriler.length,
            itemBuilder: (context, index) {
              final seri = stok.seriler[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.qr_code, color: Colors.green[700], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seri.seriNo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                seri.hucre,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3b82f6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        seri.miktar.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3b82f6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
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
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.isNotEmpty) {
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
                  child: const Text('Barkodu kameranın önüne tutun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model Classes (aynı kalıyor)
class StokGrup {
  final String stokKodu;
  final double toplamStokMiktar;
  final int subeKodu;
  final int depoKodu;
  final String? koleksiyon;
  final String? eskiDesen;
  final List<SeriDetay> seriler;

  StokGrup({
    required this.stokKodu,
    required this.toplamStokMiktar,
    required this.subeKodu,
    required this.depoKodu,
    this.koleksiyon,
    this.eskiDesen,
    required this.seriler,
  });

  factory StokGrup.fromJson(Map<String, dynamic> json) {
    return StokGrup(
      stokKodu: json['stokKodu'] ?? '',
      toplamStokMiktar: (json['toplamStokMiktar'] ?? 0).toDouble(),
      subeKodu: json['subeKodu'] ?? 0,
      depoKodu: json['depoKodu'] ?? 0,
      koleksiyon: json['koleksiyon'],
      eskiDesen: json['eskiDesen'],
      seriler: (json['seriler'] as List?)?.map((e) => SeriDetay.fromJson(e)).toList() ?? [],
    );
  }
}

class SeriDetay {
  final String seriNo;
  final double miktar;
  final String hucre;

  SeriDetay({
    required this.seriNo,
    required this.miktar,
    required this.hucre,
  });

  factory SeriDetay.fromJson(Map<String, dynamic> json) {
    return SeriDetay(
      seriNo: json['seriNo'] ?? '',
      miktar: (json['miktar'] ?? 0).toDouble(),
      hucre: json['hucre'] ?? 'YERDE',
    );
  }
}
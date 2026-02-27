import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/services/api_service.dart';
import 'package:mobtex_mobile/screens/send_result_screen.dart';

class SendDataScreen extends StatefulWidget {
  const SendDataScreen({super.key});

  @override
  State<SendDataScreen> createState() => _SendDataScreenState();
}

class _SendDataScreenState extends State<SendDataScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _apiService = ApiService();

  List<Map<String, dynamic>> _prosesList = [];
  bool _isLoading = true;
  bool _isSending = false;
  int _totalBarcodes = 0;
  String _terminalId = '';
  final Map<int, String> _prosesNames = {
    0: 'Toptan Satış',
    1: 'Perakende Satış',
    2: 'İhracat Satış',
    3: 'Depolar Arası Transfer',
    4: 'İade',
    6: 'Arabadan Transfer',
    7: 'Depo Sayım',
    10: 'İşletmeler Arası',
    12: 'Hücre İşlemleri',
  };

  final Map<int, IconData> _prosesIcons = {
    0: Icons.shopping_cart_rounded,
    1: Icons.storefront_rounded,
    2: Icons.public_rounded,
    3: Icons.swap_horiz_rounded,
    4: Icons.assignment_return_rounded,
    6: Icons.local_shipping_rounded,
    7: Icons.inventory_rounded,
    10: Icons.business_center_rounded,
    12: Icons.grid_view_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _dbHelper.getMrtcProsesList();

    // Toplam barkod sayısını hesapla
    int total = 0;
    for (var proses in list) {
      total += (proses['barcodeCount'] as int? ?? 0);
    }

    // Terminal ID'yi al
    final termId = await _dbHelper.getTerminalId();

    setState(() {
      _prosesList = list;
      _totalBarcodes = total;
      _terminalId = termId ?? '';
      _isLoading = false;
    });
  }

  Future<void> _sendData() async {
    setState(() => _isSending = true);

    try {
      // Şirket ve terminal bilgilerini al
      final companySettings = await _dbHelper.getCompanySettings();
      final terminalId = await _dbHelper.getTerminalId();

      if (companySettings == null) {
        _showSnack('Şirket bilgileri bulunamadı', isError: true);
        setState(() => _isSending = false);
        return;
      }

      if (terminalId == null || terminalId.isEmpty) {
        _showSnack('Terminal ID bulunamadı', isError: true);
        setState(() => _isSending = false);
        return;
      }

      final companyCode = companySettings['company_code'] as String;

      // Tüm MRTc verilerini al
      final db = await _dbHelper.database;
      final allRecords = await db.query('mrtc');

      if (allRecords.isEmpty) {
        _showSnack('Gönderilecek veri bulunamadı', isError: true);
        setState(() => _isSending = false);
        return;
      }

      // API'ye gönder
      final response = await _apiService.sendMrtcData(
        companyCode: companyCode,
        terminalId: terminalId,
        prosesId: 0,
        mrtcData: allRecords,
      );

      setState(() => _isSending = false);

      if (response['success'] == true) {
        // Başarılı - MRTc tablosunu temizle
        await _dbHelper.deleteAllMrtc();

        // Sonuç ekranına git
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SendResultScreen(
                response: response['data'],
              ),
            ),
          );
        }
      } else {
        // Hata
        _showErrorDialog(response['errorMessage'] ?? 'Bilinmeyen hata');
      }
    } catch (e) {
      setState(() => _isSending = false);
      _showErrorDialog('Veri gönderilirken hata oluştu: $e');
    }
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Text('Hata'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Verileri Gönder', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3b82f6),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSending
          ? _buildSendingState()
          : _buildContent(),
    );
  }

  Widget _buildSendingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 6),
          ),
          const SizedBox(height: 24),
          const Text(
            'Veriler gönderiliyor...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen bekleyin',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
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
          // İstatistik kartı
          _buildStatsCard(),
          const SizedBox(height: 24),

          // Gönder butonu
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : () {
                if (_totalBarcodes == 0) {
                  _showResendConfirmation();
                } else {
                  _sendData();
                }
              },
              icon: _isSending
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Icon(_totalBarcodes == 0 ? Icons.refresh : Icons.cloud_upload, size: 28),
              label: Text(
                _isSending
                    ? 'Gönderiliyor...'
                    : (_totalBarcodes == 0 ? 'Son Verilerden İşlem Yap' : 'Verileri Gönder'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _totalBarcodes == 0 ? const Color(0xFFf59e0b) : const Color(0xFF3b82f6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _totalBarcodes == 0
              ? [const Color(0xFFf59e0b), const Color(0xFFd97706)]
              : [const Color(0xFF3b82f6), const Color(0xFF2563eb)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_totalBarcodes == 0 ? const Color(0xFFf59e0b) : const Color(0xFF3b82f6)).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _totalBarcodes == 0 ? Icons.refresh_rounded : Icons.cloud_upload_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _totalBarcodes == 0 ? 'Veri Bulunamadı' : 'Gönderilmeye Hazır',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _totalBarcodes == 0 ? 'Okutulmuş Barkod Yok' : 'Toplam $_totalBarcodes Barkod',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  void _showResendConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFf59e0b), size: 28),
            SizedBox(width: 12),
            Text('Dikkat'),
          ],
        ),
        content: const Text(
          'Cihazınızda okutulmuş barkod bilgisi bulunmamaktadır.\n\n'
              'En son gönderdiğiniz verilerden yeniden işlem yapmak ister misiniz?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resendLastData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf59e0b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Evet, Devam Et'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendLastData() async {
    setState(() => _isSending = true);

    try {
      final companySettings = await _dbHelper.getCompanySettings();
      if (companySettings == null) {
        throw Exception('Şirket bilgileri bulunamadı');
      }

      final companyCode = companySettings['company_code'] as String;
      final subeKodu = companySettings['sube_kodu'] as int;

      final response = await _apiService.resendLastData(
        companyCode: companyCode,
        subeKodu: subeKodu,
          terminalId: _terminalId,
      );

      setState(() => _isSending = false);

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SendResultScreen(
              response: response['data'],
            ),
          ),
        );
      } else {
        _showSnack(response['errorMessage'] ?? 'İşlem başarısız', isError: true);
      }
    } catch (e) {
      setState(() => _isSending = false);
      _showSnack('Hata: $e', isError: true);
    }
  }
  Widget _buildInfoCard(int totalBarcodes) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3b82f6), Color(0xFF2563eb)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3b82f6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Gönderilmeye Hazır',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Toplam $totalBarcodes Barkod',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(color: const Color(0xFF3b82f6), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
      ],
    );
  }

  Widget _buildProsesCard(Map<String, dynamic> proses) {
    final prosesId = proses['prosesId'] as int;
    final barcodeCount = proses['barcodeCount'] as int;
    final cuvalCount = proses['cuvalCount'] as int;
    final totalMiktar = proses['totalMiktar'] as num;

    final prosesName = _prosesNames[prosesId] ?? 'Bilinmeyen İşlem';
    final icon = _prosesIcons[prosesId] ?? Icons.help_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF3b82f6), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prosesName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildStat(Icons.qr_code, '$barcodeCount'),
                    _buildStat(Icons.inventory_2, '$cuvalCount'),
                    if (totalMiktar > 0) _buildStat(Icons.scale, totalMiktar.toStringAsFixed(2)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
      ],
    );
  }
}
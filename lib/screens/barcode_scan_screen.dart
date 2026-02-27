import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/screens/scanned_list_screen.dart';
import 'package:mobtex_mobile/screens/send_data_screen.dart';

class BarcodeScanScreen extends StatefulWidget {
  final int prosesId;
  final String prosesAdi;
  final String terminalId;
  final int subeKodu;
  final int isletmeKodu;
  final int depoKodu;
  final String cariKod;
  final String plasiyerKod;
  final int dovizTipi;
  final String ozelKod1;
  final String ozelKod2;
  final String fiyatTipi;
  final bool showMiktar;
  final bool showCuvalTir;
  final int? hedefSubeKodu;
  final int? hedefDepoKodu;


  const BarcodeScanScreen({
    super.key,
    required this.prosesId,
    required this.prosesAdi,
    required this.terminalId,
    required this.subeKodu,
    required this.isletmeKodu,
    required this.depoKodu,
    required this.cariKod,
    required this.plasiyerKod,
    required this.dovizTipi,
    required this.ozelKod1,
    required this.ozelKod2,
    required this.fiyatTipi,
    required this.showMiktar,
    this.showCuvalTir = true,
    this.hedefSubeKodu,
    this.hedefDepoKodu,
  });

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _barcodeController = TextEditingController();
  final _miktarController = TextEditingController(text: '0');
  final _barcodeFocus = FocusNode();

  int _cuvalNo = 0;
  int _tirNo = 0;
  bool _deleteMode = false;

  int _barcodeCount = 0;
  int _cuvalCount = 0;
  String _lastBarcode = '-';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _miktarController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await _dbHelper.getMrtcStats(widget.prosesId);
    setState(() {
      _barcodeCount = stats['barcodeCount'] ?? 0;
      _cuvalCount = stats['cuvalCount'] ?? 0;
    });
  }

  Future<void> _processBarcodeInput(String barcode) async {
    if (barcode.trim().isEmpty) return;

    final trimmedBarcode = barcode.trim();

    if (_deleteMode) {
      final exists = await _dbHelper.isBarcodeExists(trimmedBarcode, widget.prosesId);
      if (!exists) {
        _showSnack('Barkod daha once okutulmamis!', isError: true);
        _barcodeController.clear();
        _barcodeFocus.requestFocus();
        return;
      }

      await _dbHelper.deleteMrtcByBarcode(trimmedBarcode, widget.prosesId);
      _showSnack('Barkod silindi');
      _barcodeController.clear();
      setState(() => _lastBarcode = '-');
      await _loadStats();
      _barcodeFocus.requestFocus();
      return;
    }

    // Barkod kontrolü
    final exists = await _dbHelper.isBarcodeExists(trimmedBarcode, widget.prosesId);

    if (exists) {
      // TOPTAN SATIŞ: Zaten varsa pas geç
      if (!widget.showMiktar) {
        _showSnack('Bu barkod zaten kayitli, pas gecildi', isError: true);
        _barcodeController.clear();
        _barcodeFocus.requestFocus();
        return;
      }

      // PERAKENDE SATIŞ: Miktar varsa güncelle
      final miktar = double.tryParse(_miktarController.text) ?? 0.0;

      if (miktar > 0) {
        await _dbHelper.updateMrtcMiktar(trimmedBarcode, widget.prosesId, miktar);
        setState(() => _lastBarcode = trimmedBarcode);
        _showSnack('Barkod miktari guncellendi');
        _barcodeController.clear();
        _miktarController.text = '0';
        await _loadStats();
        _barcodeFocus.requestFocus();
        return;
      } else {
        _showSnack('Bu barkod zaten kayitli, miktar sifir', isError: true);
        _barcodeController.clear();
        _barcodeFocus.requestFocus();
        return;
      }
    }

    // Yeni kayıt
    final miktar = widget.showMiktar ? (double.tryParse(_miktarController.text) ?? 0.0) : 0.0;

    await _dbHelper.insertMrtc({
      'BK': trimmedBarcode,
      'CN': widget.showCuvalTir && _cuvalNo > 0 ? _cuvalNo.toString() : null,
      'TN': widget.showCuvalTir && _tirNo > 0 ? _tirNo.toString() : null,
      'DT': widget.dovizTipi,
      'DP': widget.depoKodu,
      'D2': widget.hedefDepoKodu,
      'MK': widget.cariKod,
      'PK': widget.plasiyerKod.isNotEmpty ? widget.plasiyerKod : null,
      'TI': widget.terminalId,
      'PI': widget.prosesId,
      'SB': widget.subeKodu,
      'HS': widget.hedefSubeKodu,
      'IL': widget.isletmeKodu,
      'HI': null,
      'O1': widget.ozelKod1,
      'O2': widget.ozelKod2,
      'BR': null,
      'DV': null,
      'PR': null,
      'MT': miktar,
      'FT': widget.fiyatTipi,
      'EKI1': null,
      'EKI2': null,
      'EKI3': null,
      'EKF1': null,
      'EKF2': null,
      'EKF3': null,
      'EKS1': null,
      'EKS2': null,
      'EKS3': null,
      'FL': null,
    });

    setState(() => _lastBarcode = trimmedBarcode);
    _showSnack('Barkod kaydedildi');
    _barcodeController.clear();
    if (widget.showMiktar) _miktarController.text = '0';
    await _loadStats();
    _barcodeFocus.requestFocus();
  }
  void _openCameraScanner() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CameraScannerDialog(
        onBarcodeDetected: (barcode) {
          Navigator.pop(context);
          _barcodeController.text = barcode;
          _processBarcodeInput(barcode).then((_) {
            _barcodeFocus.requestFocus();
          });
        },
      ),
    );
  }

  void _showScannedList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannedListScreen(
          prosesId: widget.prosesId,
          prosesAdi: widget.prosesAdi,
          cariKod: widget.cariKod,
        ),
      ),
    ).then((_) => _loadStats());
  }

  void _navigateToSendData() async {
    if (_barcodeCount == 0) {
      _showSnack('Gönderilecek barkod bulunamadı', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendDataScreen(),
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
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.prosesAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10b981),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: _showScannedList,
            tooltip: 'Okutulan Barkodlar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildStatsCard(),
            const SizedBox(height: 20),
            _buildBarcodeInputCard(),
            const SizedBox(height: 20),
            if (widget.showCuvalTir) ...[
              _buildCountersCard(),
              const SizedBox(height: 20),
            ],
            if (widget.showMiktar) ...[
              _buildMiktarCard(),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _navigateToSendData,
                icon: const Icon(Icons.cloud_upload_rounded, size: 26),
                label: const Text('Verileri Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3b82f6), Color(0xFF2563eb)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('İşlem: ${widget.prosesAdi} (PI: ${widget.prosesId})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Terminal: ${widget.terminalId} | Depo: ${widget.depoKodu}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Barkod', _barcodeCount.toString(), Icons.qr_code_rounded, const Color(0xFF10b981)),
              ),
              Container(width: 1, height: 35, color: Colors.grey[300]),
              Expanded(
                child: _buildStatItem('Çuval', _cuvalCount.toString(), Icons.inventory_2_rounded, const Color(0xFFf59e0b)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10b981), size: 18),
                const SizedBox(width: 8),
                Text('Son Okunan:', style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_lastBarcode,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1e293b)),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBarcodeInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Barkod Okutma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  focusNode: _barcodeFocus,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Barkod giriniz veya okutunuz',
                    prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF10b981)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFF10b981), width: 2)),
                  ),
                  onSubmitted: _processBarcodeInput,
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _openCameraScanner,
                icon: const Icon(Icons.camera_alt_rounded, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981).withOpacity(0.1),
                  foregroundColor: const Color(0xFF10b981),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _deleteMode,
                onChanged: (v) => setState(() => _deleteMode = v ?? false),
                activeColor: Colors.red[700],
              ),
              const Text('Okutulan barkodu iptal et', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Çuval & Tır Bilgisi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildCounter('Çuval No', _cuvalNo, (v) => setState(() => _cuvalNo = v))),
              const SizedBox(width: 16),
              Expanded(child: _buildCounter('Tır No', _tirNo, (v) => setState(() => _tirNo = v))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              IconButton(onPressed: () => onChanged(value > 0 ? value - 1 : 0), icon: const Icon(Icons.remove, size: 20), padding: const EdgeInsets.all(8)),
              Expanded(child: Text(value.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add, size: 20), padding: const EdgeInsets.all(8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiktarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Miktar Girişi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _miktarController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Miktar',
              prefixIcon: const Icon(Icons.scale_rounded, color: Color(0xFFf59e0b)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFf59e0b), width: 2)),
            ),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          ),
        ],
      ),
    );
  }
}

// Kamera tarama dialog'u
class _CameraScannerDialog extends StatefulWidget {
  final Function(String) onBarcodeDetected;

  const _CameraScannerDialog({required this.onBarcodeDetected});

  @override
  State<_CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<_CameraScannerDialog> {
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
import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/screens/proses_detail_screen.dart';

class ScannedBarcodesScreen extends StatefulWidget {
  const ScannedBarcodesScreen({super.key});

  @override
  State<ScannedBarcodesScreen> createState() => _ScannedBarcodesScreenState();
}

class _ScannedBarcodesScreenState extends State<ScannedBarcodesScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _prosesList = [];
  bool _isLoading = true;

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

  final Map<int, Color> _prosesColors = {
    0: const Color(0xFF10b981),
    1: const Color(0xFF059669),
    2: const Color(0xFF3b82f6),
    3: const Color(0xFFf59e0b),
    4: const Color(0xFFef4444),
    6: const Color(0xFF8b5cf6),
    7: const Color(0xFF06b6d4),
    10: const Color(0xFFec4899),
    12: const Color(0xFF6366f1),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _dbHelper.getMrtcProsesList();
    setState(() {
      _prosesList = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Sil'),
        content: const Text('Tüm okutulan barkodları silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteAllMrtc();
      _showSnack('Tüm kayıtlar silindi');
      await _loadData();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10b981),
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
        title: const Text('Okutulan Barkodlar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10b981),
        elevation: 0,
        actions: [
          if (_prosesList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _deleteAll,
              tooltip: 'Tümünü Sil',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prosesList.isEmpty
          ? _buildEmpty()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _prosesList.length,
        itemBuilder: (context, index) => _buildProsesCard(_prosesList[index]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Henüz barkod okutulmadı', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildProsesCard(Map<String, dynamic> proses) {
    final prosesId = proses['prosesId'] as int;
    final barcodeCount = proses['barcodeCount'] as int;
    final cuvalCount = proses['cuvalCount'] as int;
    final totalMiktar = proses['totalMiktar'] as num;

    final prosesName = _prosesNames[prosesId] ?? 'Bilinmeyen İşlem';
    final icon = _prosesIcons[prosesId] ?? Icons.help_outline;
    final color = _prosesColors[prosesId] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProsesDetailScreen(
                  prosesId: prosesId,
                  prosesAdi: prosesName,
                  color: color,
                ),
              ),
            ).then((_) => _loadData());
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prosesName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildStat(Icons.qr_code, '$barcodeCount Barkod', color),
                          const SizedBox(width: 12),
                          _buildStat(Icons.inventory_2, '$cuvalCount Çuval', const Color(0xFFf59e0b)),
                          if (totalMiktar > 0) ...[
                            const SizedBox(width: 12),
                            _buildStat(Icons.scale, '${totalMiktar.toStringAsFixed(2)}', const Color(0xFF3b82f6)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
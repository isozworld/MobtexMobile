import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';

class ProsesDetailScreen extends StatefulWidget {
  final int prosesId;
  final String prosesAdi;
  final Color color;

  const ProsesDetailScreen({
    super.key,
    required this.prosesId,
    required this.prosesAdi,
    required this.color,
  });

  @override
  State<ProsesDetailScreen> createState() => _ProsesDetailScreenState();
}

class _ProsesDetailScreenState extends State<ProsesDetailScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final records = await _dbHelper.getMrtcDetailsByProses(widget.prosesId);
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(int id, String barcode) async {
    await _dbHelper.deleteMrtcByBarcode(barcode, widget.prosesId);
    _showSnack('Kayıt silindi');
    await _loadData();
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Sil'),
        content: Text('${widget.prosesAdi} için tüm kayıtları silmek istediğinizden emin misiniz?'),
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
      await _dbHelper.deleteAllMrtcByProses(widget.prosesId);
      _showSnack('Tüm kayıtlar silindi');
      Navigator.pop(context);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: widget.color,
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
        title: Text(widget.prosesAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: widget.color,
        elevation: 0,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _deleteAll,
              tooltip: 'Tümünü Sil',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? _buildEmpty()
          : Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildList()),
        ],
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
          Text('Kayıt bulunamadı', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalBarcodes = _records.length;
    final uniqueCuval = _records.where((r) => r['cuvalNo'] != null).map((r) => r['cuvalNo']).toSet().length;
    final totalMiktar = _records.fold<double>(0, (sum, r) => sum + ((r['miktar'] as num?) ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.info_outline, color: widget.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.prosesAdi} Detayları',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toplam $totalBarcodes kayıt',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildHeaderStat('Barkod', totalBarcodes.toString(), widget.color),
              const SizedBox(width: 20),
              _buildHeaderStat('Çuval', uniqueCuval.toString(), const Color(0xFFf59e0b)),
              if (totalMiktar > 0) ...[
                const SizedBox(width: 20),
                _buildHeaderStat('Toplam', totalMiktar.toStringAsFixed(2), const Color(0xFF3b82f6)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            label == 'Barkod' ? Icons.qr_code : label == 'Çuval' ? Icons.inventory_2 : Icons.scale,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.qr_code_2_rounded, color: widget.color, size: 24),
            ),
            title: Text(
              record['barkod'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (record['cariIsim'] != null)
                  Text(
                    '${record['cariKod']} - ${record['cariIsim']}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1e293b)),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (record['depoKodu'] != null)
                      _buildDetailChip('Depo', record['depoKodu'].toString(), Icons.warehouse),
                    if (record['subeKodu'] != null)
                      _buildDetailChip('Şube', record['subeKodu'].toString(), Icons.store),
                    if (record['isletmeKodu'] != null)
                      _buildDetailChip('İşletme', record['isletmeKodu'].toString(), Icons.business),
                    if (record['cuvalNo'] != null && record['cuvalNo'].toString().isNotEmpty)
                      _buildDetailChip('Çuval', record['cuvalNo'].toString(), Icons.inventory_2),
                    if (record['tirNo'] != null && record['tirNo'].toString().isNotEmpty)
                      _buildDetailChip('Tır', record['tirNo'].toString(), Icons.local_shipping),
                    if (record['miktar'] != null && record['miktar'] > 0)
                      _buildDetailChip('Miktar', record['miktar'].toString(), Icons.scale, color: const Color(0xFF3b82f6)),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteRecord(record['ID'] as int, record['barkod'] as String),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, IconData icon, {Color? color}) {
    final chipColor = color ?? Colors.grey[700]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: chipColor),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 11, color: chipColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
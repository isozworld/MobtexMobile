import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';

class ScannedListScreen extends StatefulWidget {
  final int prosesId;
  final String prosesAdi;
  final String cariKod;

  const ScannedListScreen({
    super.key,
    required this.prosesId,
    required this.prosesAdi,
    required this.cariKod,
  });

  @override
  State<ScannedListScreen> createState() => _ScannedListScreenState();
}

class _ScannedListScreenState extends State<ScannedListScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _dbHelper.getMrtcByProses(widget.prosesId);
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(int id, String barcode) async {
    await _dbHelper.deleteMrtcByBarcode(barcode, widget.prosesId);
    _showSnack('Kayıt silindi');
    await _loadRecords();
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Sil'),
        content: const Text('Tüm kayıtları silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteAllMrtcByProses(widget.prosesId);
      _showSnack('Tüm kayıtlar silindi');
      await _loadRecords();
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Okutulan Barkodlar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF10b981),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.prosesAdi}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Müşteri: ${widget.cariKod}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildHeaderStat('Toplam Kayıt', _records.length.toString(), const Color(0xFF10b981)),
              const SizedBox(width: 20),
              _buildHeaderStat('Çuval', _getCuvalCount().toString(), const Color(0xFFf59e0b)),
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
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.check_circle, color: color, size: 16),
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

  int _getCuvalCount() {
    final cuvalSet = <String>{};
    for (var rec in _records) {
      if (rec['CN'] != null && rec['CN'].toString().isNotEmpty) {
        cuvalSet.add(rec['CN'].toString());
      }
    }
    return cuvalSet.length;
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

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildListItem(record);
      },
    );
  }

  Widget _buildListItem(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF10b981)),
        ),
        title: Text(record['BK'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record['CN'] != null) Text('Çuval: ${record['CN']}', style: const TextStyle(fontSize: 12)),
            if (record['MT'] != null && record['MT'] > 0) Text('Miktar: ${record['MT']}', style: const TextStyle(fontSize: 12)),
            Text('Depo: ${record['DP']}', style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteRecord(record['ID'] as int, record['BK'] as String),
        ),
      ),
    );
  }
}
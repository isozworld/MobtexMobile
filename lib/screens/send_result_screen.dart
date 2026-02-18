import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SendResultScreen extends StatelessWidget {
  final Map<String, dynamic> response;

  const SendResultScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final success = response['success'] ?? false;
    final errorMessage = response['errorMessage'];
    final results = (response['results'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final totalRecords = response['totalRecords'] ?? 0;
    final resultCount = response['resultCount'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gönderim Sonucu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: success ? const Color(0xFF10b981) : Colors.red[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusCard(success, errorMessage, totalRecords, resultCount),
            if (errorMessage != null && errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildErrorCard(errorMessage),
            ],
            if (results.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('İşlem Sonuçları'),
              const SizedBox(height: 16),
              ...results.map((result) => _buildResultCard(context, result)),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home_rounded, size: 26),
                label: const Text('Ana Sayfaya Dön', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool success, String? errorMessage, int totalRecords, int resultCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: success
              ? [const Color(0xFF10b981), const Color(0xFF059669)]
              : [Colors.red[700]!, Colors.red[900]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (success ? const Color(0xFF10b981) : Colors.red[700]!).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            success ? 'Başarıyla Gönderildi' : 'Gönderim Başarısız',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (success) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$totalRecords kayıt gönderildi, $resultCount sonuç alındı',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hata Detayı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red[900])),
                const SizedBox(height: 4),
                Text(errorMessage, style: TextStyle(fontSize: 13, color: Colors.red[800])),
              ],
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
          decoration: BoxDecoration(color: const Color(0xFF10b981), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, Map<String, dynamic> result) {
    final barkod = result['barkod'] as String?;
    final irsaliye = result['irsaliye'] as String?;
    final cariKod = result['cariKod'] as String?;
    final prosesId = result['prosesId'] as int?;
    final tarihStr = result['tarih'] as String?;
    final aciklama = result['aciklama'] as String?;
    final flag = result['flag'] as int?;

    DateTime? tarih;
    if (tarihStr != null) {
      try {
        tarih = DateTime.parse(tarihStr);
      } catch (e) {
        // ignore
      }
    }

    final isClickable = (flag == 0 || flag == 1) && irsaliye != null && irsaliye.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isClickable
              ? () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Detaylar'),
                content: const Text('Bu özellik bir sonraki versiyonda eklenecektir.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            );
          }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getFlagColor(flag).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
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
                        color: _getFlagColor(flag).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.qr_code_2_rounded, color: _getFlagColor(flag), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barkod ?? '-',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (tarih != null)
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(tarih),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    if (isClickable)
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                  ],
                ),
                if (aciklama != null && aciklama.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            aciklama,
                            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (irsaliye != null || cariKod != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (irsaliye != null && irsaliye.isNotEmpty)
                        _buildChip('İrsaliye', irsaliye, Icons.receipt_long),
                      if (cariKod != null && cariKod.isNotEmpty)
                        _buildChip('Cari', cariKod, Icons.person_outline),
                      if (prosesId != null)
                        _buildChip('PI', prosesId.toString(), Icons.category_outlined),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(fontSize: 12, color: Colors.blue[900], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getFlagColor(int? flag) {
    switch (flag) {
      case 0:
      case 1:
        return const Color(0xFF10b981);
      case 4:
        return Colors.red[700]!;
      default:
        return const Color(0xFF3b82f6);
    }
  }
}
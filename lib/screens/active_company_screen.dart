import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';

class ActiveCompanyScreen extends StatefulWidget {
  const ActiveCompanyScreen({super.key});

  @override
  State<ActiveCompanyScreen> createState() => _ActiveCompanyScreenState();
}

class _ActiveCompanyScreenState extends State<ActiveCompanyScreen> {
  final _dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? _companySettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final settings = await _dbHelper.getCompanySettings();
    setState(() {
      _companySettings = settings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF0ea5e9),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Aktif Şirket Bilgileri',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: 20,
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 80,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _companySettings == null
                      ? _buildNoData()
                      : _buildCompanyCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoData() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
              ),
            ],
          ),
          child: Icon(
            Icons.business_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Şirket Bilgisi Bulunamadı',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ayarlar > Veri Sync ekranından\nşirket kodunuzu kaydedin.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Geri Dön'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0ea5e9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyCard() {
    final syncDate = _companySettings!['last_sync'] != null
        ? DateTime.tryParse(_companySettings!['last_sync'])
        : null;
    final syncFormatted = syncDate != null
        ? '${syncDate.day.toString().padLeft(2, '0')}.${syncDate.month.toString().padLeft(2, '0')}.${syncDate.year} ${syncDate.hour.toString().padLeft(2, '0')}:${syncDate.minute.toString().padLeft(2, '0')}'
        : 'Henüz eşitlenmedi';

    final createdDate = _companySettings!['created_at'] != null
        ? DateTime.tryParse(_companySettings!['created_at'])
        : null;
    final createdFormatted = createdDate != null
        ? '${createdDate.day.toString().padLeft(2, '0')}.${createdDate.month.toString().padLeft(2, '0')}.${createdDate.year}'
        : '-';

    return Column(
      children: [
        // Ana şirket kartı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF0ea5e9).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aktif Şirket',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _companySettings!['company_code'] ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                      Icons.sync_rounded, 'Son Sync', syncFormatted),
                  _buildInfoChip(
                      Icons.calendar_today_rounded, 'Kayıt', createdFormatted),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Detay kartı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bağlantı Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                  Icons.tag_rounded, 'Şirket Kodu',
                  _companySettings!['company_code'] ?? '-'),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.cloud_rounded, 'Sunucu',
                  'http://10.1.20.55:8282'),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.storage_rounded, 'Yerel Veritabanı',
                  'mobtex.db (SQLite)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF0ea5e9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF0ea5e9), size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1e293b),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

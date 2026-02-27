import 'package:flutter/material.dart';
import 'package:mobtex_mobile/screens/seri_ambar_bakiye_screen.dart';
import 'package:mobtex_mobile/screens/seri_detay_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Raporlar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFef4444),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildReportCard(
              context,
              title: 'Seri Ambar Bakiye',
              icon: Icons.inventory_rounded,
              color: const Color(0xFF3b82f6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeriAmbarBakiyeScreen()),
              ),
            ),
            _buildReportCard(
              context,
              title: 'Seri Detay',
              icon: Icons.qr_code_2_rounded,
              color: const Color(0xFF10b981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>   SeriDetayScreen()),
              ),
            ),
            _buildReportCard(
              context,
              title: 'Satış Raporu',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFf59e0b),
              onTap: () => _showComingSoon(context, 'Satış Raporu'),
            ),
            _buildReportCard(
              context,
              title: 'Müşteri Bakiye',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF8b5cf6),
              onTap: () => _showComingSoon(context, 'Müşteri Bakiye'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature raporu yakında eklenecek'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFFef4444),
      ),
    );
  }
}
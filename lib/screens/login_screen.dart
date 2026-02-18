import 'package:flutter/material.dart';
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/services/api_service.dart';
import 'package:mobtex_mobile/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _dbHelper = DatabaseHelper.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showUrlField = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final url = await _dbHelper.getServerUrl();
    setState(() {
      _urlController.text = url;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // URL değiştiyse kaydet
    final currentUrl = await _dbHelper.getServerUrl();
    final newUrl = _urlController.text.trim();
    if (newUrl != currentUrl) {
      await _dbHelper.saveServerUrl(newUrl);
    }

    setState(() => _isLoading = true);

    final result = await _apiService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(result['message'] ?? 'Giris hatasi')),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gecerli bir URL giriniz (http:// ile baslamali)'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    await _dbHelper.saveServerUrl(url);
    setState(() => _showUrlField = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sunucu adresi kaydedildi'),
        backgroundColor: const Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: const Center(child: Icon(Icons.warehouse_rounded, size: 50, color: Color(0xFF667eea))),
                      ),
                      const SizedBox(height: 20),
                      const Text('Mobtex Mobile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Depo Yonetim Sistemi', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                      const SizedBox(height: 36),

                      // Login Kartı
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Başlık
                                const Text('Giris Yap', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
                                const SizedBox(height: 4),
                                Text('Devam etmek icin giris yapin', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 24),

                                // Kullanıcı adı
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: _inputDecoration('Kullanici Adi', Icons.person_outline_rounded),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Kullanici adi gerekli' : null,
                                ),
                                const SizedBox(height: 14),

                                // Şifre
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _inputDecoration('Sifre', Icons.lock_outline_rounded).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Sifre gerekli' : null,
                                ),
                                const SizedBox(height: 20),

                                // Giriş butonu
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF667eea),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                        : const Text('Giris Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),

                                const SizedBox(height: 20),
                                Divider(color: Colors.grey[200]),
                                const SizedBox(height: 12),

                                // Sunucu ayarları toggle
                                InkWell(
                                  onTap: () => setState(() => _showUrlField = !_showUrlField),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _showUrlField ? Icons.expand_less_rounded : Icons.settings_ethernet_rounded,
                                          size: 18,
                                          color: const Color(0xFF667eea),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sunucu Ayarlari',
                                          style: TextStyle(
                                            color: const Color(0xFF667eea),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          _showUrlField ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: Colors.grey[400],
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // URL alanı (açılır/kapanır)
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: _showUrlField
                                      ? Column(
                                          children: [
                                            const SizedBox(height: 12),
                                            TextFormField(
                                              controller: _urlController,
                                              keyboardType: TextInputType.url,
                                              decoration: _inputDecoration('Servis API URL', Icons.link_rounded).copyWith(
                                                hintText: 'http://10.1.20.55:8282',
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: _saveUrl,
                                                icon: const Icon(Icons.save_rounded, size: 18),
                                                label: const Text('Sunucu Adresini Kaydet', style: TextStyle(fontWeight: FontWeight.w600)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF667eea),
                                                  side: const BorderSide(color: Color(0xFF667eea)),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Sunucu adresi göstergesi
                      const SizedBox(height: 16),
                      FutureBuilder<String>(
                        future: _dbHelper.getServerUrl(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_done_rounded, size: 14, color: Colors.white.withOpacity(0.9)),
                                const SizedBox(width: 6),
                                Text(
                                  snap.data!,
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF667eea), width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}

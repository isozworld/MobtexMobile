import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:mobtex_mobile/helpers/database_helper.dart';
import 'package:mobtex_mobile/services/api_service.dart';
import 'package:mobtex_mobile/screens/login_screen.dart';
import 'package:mobtex_mobile/screens/home_screen.dart';
import 'package:mobtex_mobile/screens/server_setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobtex Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ══════════════════════════════════════════════════
//  SPLASH SCREEN — Perde (Curtain) Animasyonu
// ══════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _curtainController;
  late AnimationController _waveController;
  late AnimationController _logoController;
  late Animation<double> _curtainLeft;
  late Animation<double> _curtainRight;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  final _apiService = ApiService();
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();

    // Dalga animasyonu (sürekli)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Logo giriş animasyonu
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Perde açılma animasyonu
    _curtainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _curtainLeft = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(parent: _curtainController, curve: Curves.easeInOut),
    );
    _curtainRight = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _curtainController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Logo göster
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Biraz bekle
    await Future.delayed(const Duration(milliseconds: 1600));

    // Perde açılsın
    _waveController.stop();
    await _curtainController.forward();

    // Navigasyon
    if (!mounted) return;
    await _navigate();
  }

  Future<void> _navigate() async {
    final isUrlSet = await _dbHelper.isServerUrlSet();
    if (!isUrlSet) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ServerSetupScreen()),
      );
      return;
    }
    final isLoggedIn = await _apiService.isLoggedIn();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _curtainController.dispose();
    _waveController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
              ),
            ),
          ),

          // Logo ve yazı (perde arkasında)
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, _) => FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // İkon
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667eea).withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/icon/ic_launcher.png',
                            errorBuilder: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(Icons.warehouse_rounded, size: 60, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'MOBTEX',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'MOBILE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 60,
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Depo Yonetim Sistemi',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.55),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sol perde
          AnimatedBuilder(
            animation: _curtainController,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(_curtainLeft.value * size.width, 0),
                child: _CurtainPanel(
                  width: size.width / 2 + 2,
                  height: size.height,
                  isLeft: true,
                  waveAnim: _waveController,
                  color: const Color(0xFF667eea),
                ),
              );
            },
          ),

          // Sağ perde
          AnimatedBuilder(
            animation: _curtainController,
            builder: (context, _) {
              return Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                  offset: Offset(_curtainRight.value * size.width, 0),
                  child: _CurtainPanel(
                    width: size.width / 2 + 2,
                    height: size.height,
                    isLeft: false,
                    waveAnim: _waveController,
                    color: const Color(0xFF764ba2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Perde Paneli ──────────────────────────────────
class _CurtainPanel extends StatelessWidget {
  final double width;
  final double height;
  final bool isLeft;
  final AnimationController waveAnim;
  final Color color;

  const _CurtainPanel({
    required this.width,
    required this.height,
    required this.isLeft,
    required this.waveAnim,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveAnim,
      builder: (context, _) {
        return CustomPaint(
          size: Size(width, height),
          painter: _CurtainPainter(
            progress: waveAnim.value,
            isLeft: isLeft,
            color: color,
          ),
        );
      },
    );
  }
}

class _CurtainPainter extends CustomPainter {
  final double progress;
  final bool isLeft;
  final Color color;

  _CurtainPainter({required this.progress, required this.isLeft, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Kadife doku dalgaları
    const waveCount = 5;
    final waveWidth = size.width / waveCount;
    final amplitude = waveWidth * 0.18;
    final phase = progress * 2 * math.pi;

    for (int i = 0; i <= waveCount; i++) {
      final x = isLeft
          ? size.width - i * waveWidth
          : i * waveWidth;

      final shade = (i % 2 == 0) ? 0.0 : 0.15;
      final paint = Paint()
        ..color = Color.lerp(color, Colors.black, shade)!.withOpacity(0.95)
        ..style = PaintingStyle.fill;

      final path = Path();

      if (isLeft) {
        path.moveTo(0, 0);
        path.lineTo(x, 0);
        for (double y = 0; y <= size.height; y += 4) {
          final wave = math.sin(y / size.height * 3 * math.pi + phase + i * 0.5) * amplitude;
          path.lineTo(x + wave, y);
        }
        path.lineTo(0, size.height);
        path.close();
      } else {
        path.moveTo(size.width, 0);
        path.lineTo(x, 0);
        for (double y = 0; y <= size.height; y += 4) {
          final wave = math.sin(y / size.height * 3 * math.pi + phase + i * 0.5) * amplitude;
          path.lineTo(x - wave, y);
        }
        path.lineTo(size.width, size.height);
        path.close();
      }

      canvas.drawPath(path, paint);
    }

    // Perde kenar çizgisi (parlak)
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final edgePath = Path();
    final edgeX = isLeft ? size.width : 0.0;

    edgePath.moveTo(edgeX, 0);
    for (double y = 0; y <= size.height; y += 4) {
      final wave = math.sin(y / size.height * 3 * math.pi + phase) * amplitude;
      edgePath.lineTo(isLeft ? edgeX + wave : edgeX - wave, y);
    }
    canvas.drawPath(edgePath, edgePaint);

    // Üst korniş
    final cornisePaint = Paint()
      ..color = const Color(0xFF2d2d5e)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 18), cornisePaint);

    // Korniş parlaklık çizgisi
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 18), Offset(size.width, 18), shinePaint);
  }

  @override
  bool shouldRepaint(_CurtainPainter old) => old.progress != progress;
}

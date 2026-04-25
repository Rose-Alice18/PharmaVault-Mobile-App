import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _dotsCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _bgFade    = CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.0, 0.3, curve: Curves.easeIn));
    _logoFade  = CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.1, 0.5, curve: Curves.easeIn));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.1, 0.6, curve: Curves.elasticOut)));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)));
    _textFade  = CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.4, 0.8, curve: Curves.easeIn));

    _mainCtrl.forward();
    _init();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().initialize();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      context.read<NotificationProvider>().subscribe(auth.userId!);
      Navigator.pushReplacementNamed(
        context,
        auth.isPharmacy ? '/pharmacy-main' : '/main',
      );
      return;
    }
    final seen = await StorageService().isOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, seen ? '/login' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _mainCtrl,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1DB954), AppColors.primary, Color(0xFF0D6B35)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // ── Decorative circles ──────────────────────────────────
                Opacity(
                  opacity: _bgFade.value,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -size.width * 0.25,
                        right: -size.width * 0.2,
                        child: Container(
                          width: size.width * 0.75,
                          height: size.width * 0.75,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(18),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: size.height * 0.08,
                        left: -size.width * 0.3,
                        child: Container(
                          width: size.width * 0.7,
                          height: size.width * 0.7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(12),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: size.height * 0.25,
                        right: -size.width * 0.1,
                        child: Container(
                          width: size.width * 0.35,
                          height: size.width * 0.35,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Main content ─────────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(50),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                                BoxShadow(
                                  color: Colors.white.withAlpha(30),
                                  blurRadius: 12,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Green circle background inside logo
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF22C55E), AppColors.primary],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Icon(Icons.local_pharmacy_rounded, size: 44, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Text content
                      FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: [
                              const Text(
                                'PharmaVault',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withAlpha(40), width: 1),
                                ),
                                child: Text(
                                  'Your Digital Pharmacy Companion',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withAlpha(220),
                                    letterSpacing: 0.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Loading dots ─────────────────────────────────────────
                Positioned(
                  bottom: size.height * 0.08,
                  left: 0, right: 0,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: _LoadingDots(controller: _dotsCtrl),
                  ),
                ),

                // ── Version tag ──────────────────────────────────────────
                Positioned(
                  bottom: size.height * 0.04,
                  left: 0, right: 0,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Text(
                      'v1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(120), letterSpacing: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Animated loading dots ────────────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay  = i * 0.25;
            final t      = ((controller.value + delay) % 1.0);
            final scale  = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            final alpha  = (100 + 155 * (t < 0.5 ? t * 2 : (1 - t) * 2)).toInt();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(alpha),
              ),
            );
          }),
        );
      },
    );
  }
}

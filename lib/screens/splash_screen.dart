import 'package:flutter/material.dart';

import '../design/logo.dart';
import '../design/tokens.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// מסך פתיחה (Splash Screen)
/// ───────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _dotsController;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // אנימציית כניסה - הלוגו והשם מופיעים בהדרגה
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();

    // אנימציית הנקודות הפועמות
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bgApp,
      body: Stack(
        children: [
          // זוהר עדין במרכז
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.brandViolet.withValues(alpha: 0.18),
                    c.brandViolet.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // תוכן מרכזי
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Logo(variant: LogoVariant.mark, markSize: 88),
                    const SizedBox(height: 26),
                    Text(
                      'FINOVA',
                      style: FType.wordmark.copyWith(
                        fontSize: 34,
                        letterSpacing: 2.7,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // טאגליין
                    Text(
                      'ניתוח מניות חכם, בשנייה',
                      style: FType.body.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: 30),
                    // נקודות פועמות
                    _buildPulsingDots(),
                  ],
                ),
              ),
            ),
          ),
          // קרדיט בתחתית
          Positioned(
            bottom: 34,
            left: 0,
            right: 0,
            child: Text(
              '© 2026 Idan Amrani',
              textAlign: TextAlign.center,
              style: FType.micro.copyWith(color: c.textQuiet),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // כל נקודה פועמת בעיכוב שונה
            final t = (_dotsController.value - i * 0.2) % 1.0;
            final opacity =
                0.25 + 0.65 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.c.brandVioletBright.withValues(alpha: opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

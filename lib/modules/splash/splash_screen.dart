import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/modules/home/home_screen.dart';
import 'package:superdriver_admin/modules/login/login_screen.dart';
import 'package:superdriver_admin/shared/themes/colors_custom.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  static const _mainDuration = Duration(milliseconds: 3500);
  static const _navigationDelay = Duration(milliseconds: 4000);

  late final AnimationController _dotsCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _dividerWidth;
  late final Animation<double> _dotsFade;
  late final Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(vsync: this, duration: _mainDuration);
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _initAnimations();
    _mainCtrl.forward();
    _dotsCtrl.repeat();
    _navigateAfterDelay();
  }

  void _initAnimations() {
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.17, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.14, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.085, 0.23, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.085, 0.23, curve: Curves.easeOutCubic),
      ),
    );

    _dividerWidth = Tween<double>(begin: 0.0, end: 120.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.14, 0.285, curve: Curves.easeOutCubic),
      ),
    );

    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.285, 0.37, curve: Curves.easeIn),
      ),
    );

    _screenFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.91, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(_navigationDelay);
    if (!mounted) return;

    final isLoggedIn = _resolveLoginState();
    final destination = isLoggedIn ? const HomeScreen() : const LoginScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  bool _resolveLoginState() {
    try {
      return locator<SharedPreferencesRepository>().isLoggedIn;
    } catch (e) {
      debugPrint('SplashScreen – could not resolve login state: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _mainCtrl,
        builder: (context, _) {
          return FadeTransition(
            opacity: _screenFade,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorsCustom.background,
                    Colors.white,
                    ColorsCustom.primary.withValues(alpha: 0.04),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                child: SizedBox.expand(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      _buildLogo(),
                      const SizedBox(height: 28),
                      _buildText(),
                      const SizedBox(height: 20),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      const Spacer(flex: 2),
                      _buildLoadingDots(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Opacity(
      opacity: _logoFade.value,
      child: Transform.scale(
        scale: _logoScale.value,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: ColorsCustom.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: ColorsCustom.secondary.withValues(alpha: 0.08),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/icons/admin_logo_transparent.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Opacity(
      opacity: _textFade.value,
      child: Transform.translate(
        offset: Offset(0, _textSlide.value),
        child: Column(
          children: [
            Text(
              'SUPERDRIVER',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: ColorsCustom.primary,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Admin Panel',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: ColorsCustom.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final w = _dividerWidth.value;
    return SizedBox(
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: (w - 10).clamp(0.0, double.infinity) / 2,
            height: 2,
            decoration: BoxDecoration(
              color: ColorsCustom.secondary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          if (w > 10)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: ColorsCustom.secondary,
                shape: BoxShape.circle,
              ),
            ),
          Container(
            width: (w - 10).clamp(0.0, double.infinity) / 2,
            height: 2,
            decoration: BoxDecoration(
              color: ColorsCustom.secondary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Opacity(
      opacity: _dotsFade.value,
      child: AnimatedBuilder(
        animation: _dotsCtrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final phase = (_dotsCtrl.value - i * 0.25) % 1.0;
              final opacity = (0.3 + 0.7 * _pulse(phase)).clamp(0.0, 1.0);

              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: ColorsCustom.primary.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  double _pulse(double phase) {
    return (1.0 + math.cos(2.0 * math.pi * phase)) / 2.0;
  }
}

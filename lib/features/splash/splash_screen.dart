// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../core/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeLogo;
  late Animation<double> _fadeText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeLogo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _fadeText = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo in Stack with "rakit" effect
            FadeTransition(
              opacity: _fadeLogo,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Large subtle outer ring
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.12),
                        width: 8,
                      ),
                    ),
                  ),
                  // Small inner ring (layered)
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.27),
                        width: 2.2,
                      ),
                    ),
                  ),
                  // Line at the bottom, like a module connector
                  Positioned(
                    bottom: 10,
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.26),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Main Logo
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.5),
                        width: 1.8,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Image.asset(
                        'assets/images/ezzen.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Title + subtitle
            FadeTransition(
              opacity: _fadeText,
              child: Column(
                children: [
                  const Text(
                    'Point of Sale',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Solusi Bisnis Digital Terdepan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.cyan.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Simple loading indicator
            FadeTransition(
              opacity: _fadeText,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

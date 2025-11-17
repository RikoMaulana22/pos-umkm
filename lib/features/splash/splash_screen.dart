// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../core/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    Timer(
      const Duration(seconds: 3),
      () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthGate()),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E27),
              const Color(0xFF1A1F3A),
              const Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ✨ Animated Radial Gradient Background (Halus)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GradientBackgroundPainter(
                      animationValue: _animationController.value,
                    ),
                  );
                },
              ),
            ),

            // ✨ Animated Particle Effect (Subtle)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ParticlePainter(
                      animationValue: _animationController.value,
                    ),
                  );
                },
              ),
            ),

            // ✨ Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo dengan Glow Effect
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // ✨ Glow Background dengan Blur
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5 +
                                          (_animationController.value * 0.2)),
                                      blurRadius: 60 +
                                          (_animationController.value * 20),
                                      offset: const Offset(0, 0),
                                    ),
                                    BoxShadow(
                                      color: Colors.cyan.withOpacity(0.3 +
                                          (_animationController.value * 0.1)),
                                      blurRadius: 40 +
                                          (_animationController.value * 15),
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // ✨ Logo Container dengan Border
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyan.withOpacity(0.5),
                                width: 2,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.withOpacity(0.1),
                                  Colors.cyan.withOpacity(0.05),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyan.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/ezzen.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          // ✨ Rotating Ring (Subtle)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle:
                                      _animationController.value * math.pi * 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.cyan.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ✨ App Name dengan Tech Style
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 2,
                                color: Colors.cyan,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Point of Sale',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 3.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.cyan,
                                      blurRadius: 20,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 24,
                                height: 2,
                                color: Colors.cyan,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Solusi Bisnis Digital Terdepan | Efisien & Andal',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.cyan.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  // ✨ Tech Loading Dots
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 100,
                          height: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  final delayedValue =
                                      (_animationController.value * 2.0 -
                                              (index * 0.3))
                                          .clamp(0.0, 1.0);
                                  final scale = 0.5 +
                                      (math.sin(delayedValue * math.pi) * 0.5);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.cyan,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.cyan
                                                  .withOpacity(scale),
                                              blurRadius: 8,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Memuat sistem...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.cyan.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✨ Status Bar at Bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.cyan.withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sistem Siap',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✨ GANTI TechGridPainter dengan GradientBackgroundPainter (Smooth Gradient)
class GradientBackgroundPainter extends CustomPainter {
  final double animationValue;

  GradientBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // ✨ Smooth radial gradient bergerak
    final center = Offset(
      size.width / 2 + (math.sin(animationValue * math.pi * 2) * 50),
      size.height / 2 + (math.cos(animationValue * math.pi * 2) * 50),
    );

    final paint = Paint();
    const colors = [
      Color.fromARGB(60, 0, 255, 255), // Cyan
      Color.fromARGB(30, 0, 150, 255), // Blue
      Color.fromARGB(0, 10, 14, 39), // Transparent
    ];
    const stops = [0.0, 0.5, 1.0];

    paint.shader = RadialGradient(
      colors: colors,
      stops: stops,
      radius: 400 + (animationValue * 100),
    ).createShader(Rect.fromCircle(center: center, radius: 500));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ✨ Particle Painter (Halus & Subtle)
class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyan.withOpacity(0.4);

    final random = math.Random(42);

    for (int i = 0; i < 15; i++) {
      // Animated particle positions
      final x = (random.nextDouble() * size.width +
              (animationValue * 30 * math.cos(i.toDouble()))) %
          size.width;
      final y = (random.nextDouble() * size.height +
              (animationValue * 30 * math.sin(i.toDouble()))) %
          size.height;

      // Varying sizes dengan smooth animation
      final radius = 1.5 +
          (random.nextDouble() * 1.5) +
          (math.sin(animationValue * math.pi * 2 + i) * 0.5);

      // Draw dengan glow effect
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = Colors.cyan.withOpacity(0.3 + (radius * 0.1)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

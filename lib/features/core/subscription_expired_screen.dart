// lib/features/core/subscription_expired_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'screens/subscription_package_screen.dart';

class SubscriptionExpiredScreen extends StatefulWidget {
  final String storeId;
  final String userRole;

  const SubscriptionExpiredScreen({
    super.key,
    required this.storeId,
    required this.userRole,
  });

  @override
  State<SubscriptionExpiredScreen> createState() =>
      _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends State<SubscriptionExpiredScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.userRole == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // ✨ Elegant Tech Background
          Positioned.fill(
            child: CustomPaint(
              painter: ElegantTechBackgroundPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // ✨ Animated Header Section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildAnimatedHeader(),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // ✨ Message Section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMessageSection(isAdmin),
                    ),

                    const SizedBox(height: 60),

                    // ✨ Action Buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildActionButtons(isAdmin),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Column(
      children: [
        // ✨ Animated Icon Container
        Stack(
          alignment: Alignment.center,
          children: [
            // Tech accent ring (rotating)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * math.pi * 2,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main Icon Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withOpacity(0.15),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.timer_off_rounded,
                size: 60,
                color: Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ✨ Title
        const Text(
          'Langganan Telah Berakhir',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // ✨ Subtitle
        Text(
          'Masa percobaan atau paket Anda telah habis',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMessageSection(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✨ Icon + Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_rounded,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isAdmin ? 'Informasi Admin' : 'Informasi Kasir',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ✨ Message Text
          Text(
            isAdmin
                ? 'Masa berlaku langganan Anda telah berakhir. Untuk melanjutkan menggunakan semua fitur POS UMKM, silakan perbarui paket langganan Anda sekarang.'
                : 'Langganan toko ini telah berakhir. Hanya Admin atau Owner toko yang dapat memperbarui paket. Silakan hubungi Admin/Owner Anda untuk mengaktifkan kembali layanan.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // ✨ What Happens Next
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.red[700],
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Akses semua fitur akan terbatas sampai langganan diperbarui',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isAdmin) {
    return Column(
      children: [
        // ✨ Upgrade Button (Hanya untuk Admin)
        if (isAdmin) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SubscriptionPackageScreen(storeId: widget.storeId),
                  ),
                );
              },
              icon: const Icon(Icons.upgrade_rounded, size: 20),
              label: const Text(
                'Lihat Paket Berlangganan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ✨ Logout Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(
                color: Colors.grey[300]!,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ✨ Help Text
        Text(
          isAdmin
              ? 'Hubungi support jika ada pertanyaan tentang paket'
              : 'Hubungi Admin Anda atau support untuk bantuan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ✨ Elegant Tech Background Painter
class ElegantTechBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const colors = [Color(0xFFFAFAFA), Color(0xFFF5F7F5)];
    const stops = [0.0, 1.0];

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle accent lines
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.04)
      ..strokeWidth = 1.5;

    for (double x = 0; x < size.width; x += 100) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * 0.4),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

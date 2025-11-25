// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  final void Function()? onLoginTap;
  const RegisterScreen({super.key, required this.onLoginTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController storeNameController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();
  }

  void signUp() async {
    // Validasi
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        usernameController.text.isEmpty ||
        storeNameController.text.isEmpty) {
      _showErrorSnackBar("Semua field harus diisi");
      return;
    }

    if (!_isValidEmail(emailController.text)) {
      _showErrorSnackBar("Format email tidak valid");
      return;
    }

    if (passwordController.text.length < 6) {
      _showErrorSnackBar("Password minimal 6 karakter");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showErrorSnackBar("Password dan Konfirmasi Password tidak cocok");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUpAdminAndStore(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        username: usernameController.text.trim(),
        storeName: storeNameController.text.trim(),
      );

      if (mounted) {
        _showSuccessSnackBar(
            "Akun berhasil dibuat! Silakan login dengan kredensial Anda.");
        Future.delayed(const Duration(seconds: 1), () {
          widget.onLoginTap?.call();
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Gagal mendaftar: ${e.toString()}");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    storeNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // ✨ Elegant Tech Background
            Positioned.fill(
              child: CustomPaint(
                painter: ElegantTechBackgroundPainter(),
              ),
            ),

            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // ✨ Premium Header
                      _buildPremiumHeader(),

                      const SizedBox(height: 40),

                      // ✨ Form Container
                      _buildFormContainer(),

                      const SizedBox(height: 32),

                      // ✨ Login Section
                      _buildLoginSection(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // ✨ Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _animationController.value *
                                        math.pi *
                                        2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF1B5E20)
                                              .withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1B5E20),
                                ),
                                strokeWidth: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Membuat akun Anda...",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Column(
      children: [
        // ✨ Animated Logo with Tech Accent
        Stack(
          alignment: Alignment.center,
          children: [
            // Tech accent ring
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * math.pi,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/ezzenlogo.png',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ✨ Welcome Text
        const Text(
          'Buat Akun Anda Sekarang',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Mulai trial gratis 30 hari tanpa perlu kartu kredit',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFormContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ✨ Store Name Field
          _buildElegantInputField(
            controller: storeNameController,
            label: "Nama Toko",
            hint: "Contoh: Toko Makmur",
            icon: Icons.store_rounded,
          ),

          const SizedBox(height: 18),

          // ✨ Username Field
          _buildElegantInputField(
            controller: usernameController,
            label: "Nama Lengkap (Owner)",
            hint: "Nama pemilik toko",
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 18),

          // ✨ Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ✨ Email Field
          _buildElegantInputField(
            controller: emailController,
            label: "Email",
            hint: "nama@email.com",
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 18),

          // ✨ Password Field
          _buildElegantPasswordField(
            controller: passwordController,
            label: "Password",
            hint: "Minimal 6 karakter",
            isConfirm: false,
            onToggle: () {
              setState(() => _showPassword = !_showPassword);
            },
            showPassword: _showPassword,
          ),

          const SizedBox(height: 18),

          // ✨ Confirm Password Field
          _buildElegantPasswordField(
            controller: confirmPasswordController,
            label: "Konfirmasi Password",
            hint: "Ulangi password Anda",
            isConfirm: true,
            onToggle: () {
              setState(() => _showConfirmPassword = !_showConfirmPassword);
            },
            showPassword: _showConfirmPassword,
          ),

          const SizedBox(height: 20),

          // ✨ Register Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _isLoading ? "Membuat Akun..." : "Daftar & Mulai Trial",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ✨ Terms & Conditions
          Text(
            'Dengan mendaftar, Anda menyetujui Syarat & Ketentuan kami',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF1B5E20).withValues(alpha: 0.6),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1B5E20),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElegantPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isConfirm,
    required VoidCallback onToggle,
    required bool showPassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: const Color(0xFF1B5E20).withValues(alpha: 0.6),
              size: 20,
            ),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                showPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1B5E20),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B5E20).withValues(alpha: 0.08),
            const Color(0xFF1B5E20).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1B5E20).withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Sudah punya akun?',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: widget.onLoginTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E20),
                side: const BorderSide(
                  color: Color(0xFF1B5E20),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Login Sekarang',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kembali ke halaman login',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
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
      ..color = Colors.grey.withValues(alpha: 0.04)
      ..strokeWidth = 1.5;

    // Vertical accent lines
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

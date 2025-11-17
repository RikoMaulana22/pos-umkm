// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  final void Function()? onLoginTap;
  const RegisterScreen({super.key, required this.onLoginTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController storeNameController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void signUp() async {
    // ============================
    // VALIDASI
    // ============================
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        usernameController.text.isEmpty ||
        storeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Semua field harus diisi"),
          backgroundColor: Colors.red));
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Password dan Konfirmasi Password tidak cocok"),
          backgroundColor: Colors.red));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Akun berhasil dibuat. Silakan login."),
          backgroundColor: Colors.green,
        ));

        widget.onLoginTap?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal mendaftar: ${e.toString()}"),
            backgroundColor: Colors.red));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    // Logo
                    SizedBox(
                      // <-- Perbaikan: Mengganti Container dengan SizedBox
                      width: 150,
                      height: 150,
                      child: Image.asset(
                        'assets/image/ezzen.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Text(
                      "Buat Akun Toko Anda",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20)),
                    ),
                    const SizedBox(height: 25),

                    CustomTextField(
                      controller: storeNameController,
                      hintText: 'Nama Toko Anda',
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: usernameController,
                      hintText: 'Nama Lengkap (Owner)',
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: emailController,
                      hintText: 'Email (Untuk Login)',
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: confirmPasswordController,
                      hintText: 'Konfirmasi Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 25),
                    CustomButton(
                      onTap: _isLoading ? null : signUp,
                      text: "Daftar & Mulai Trial 30 Hari",
                    ),

                    const SizedBox(height: 50),

                    // Tombol ke login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun?',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onLoginTap,
                          child: const Text(
                            'Login sekarang',
                            style: TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // LOADING OVERLAY
              if (_isLoading)
                Container(
                  // Perbaikan: withOpacity -> withAlpha
                  color: Colors.black.withAlpha(128),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

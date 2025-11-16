// lib/features/auth/screens/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final void Function()? onToggleTap;
  const LoginScreen({super.key, required this.onToggleTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void signIn(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      // 'AuthGate' akan menangani navigasi jika sukses
      // Kita tidak perlu 'if (mounted) setState' di sini karena
      // widget ini akan di-unmount oleh AuthGate
    } on FirebaseAuthException catch (e) {
      // Perbaikan: Tambahkan 'if (mounted)'
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Terjadi kesalahan"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Perbaikan: Tambahkan 'if (mounted)'
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
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
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Image.asset(
                        'assets/images/pos_umkm.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: emailController,
                      hintText: 'Email',
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text('Lupa password?',
                                style: TextStyle(color: Colors.grey[600])),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    CustomButton(
                      onTap: _isLoading ? null : () => signIn(context),
                      text: "Login",
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun?',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onToggleTap,
                          child: const Text(
                            'Daftar gratis 30 hari',
                            style: TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  // Perbaikan: withOpacity -> withAlpha
                  color: Colors.black.withAlpha(128),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

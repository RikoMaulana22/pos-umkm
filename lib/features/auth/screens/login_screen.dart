// lib/features/auth/screens/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  final void Function()? onRegisterTap;
  const LoginScreen({super.key, required this.onRegisterTap});

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
        emailController.text,
        passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Terjadi kesalahan"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
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
      backgroundColor: Colors.white, // Tambahkan ini agar background putih
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),

                    // ===========================================
                    // INI BAGIAN YANG DIGANTI
                    // ===========================================
                    Container(
                      width: 250, // Sesuaikan ukurannya
                      height: 250,
                      child: Image.asset(
                        'assets/images/pos_umkm.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Kita tidak perlu Text "POS UMKM" lagi
                    // karena sudah ada di dalam gambar logo.
                    // ===========================================

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
                          Text('Lupa password?',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    CustomButton(
                      onTap: _isLoading ? null : () => signIn(context),
                      text: "Login",
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
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

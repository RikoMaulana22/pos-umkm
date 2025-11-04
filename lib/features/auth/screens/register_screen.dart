// lib/features/auth/screens/register_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

// 1. Ubah menjadi StatefulWidget
class RegisterScreen extends StatefulWidget {
  final void Function()? onLoginTap;
  const RegisterScreen({super.key, required this.onLoginTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 2. Pindahkan semua controller dan service ke dalam State
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController(); // Field baru
  final AuthService _authService = AuthService();

  // 3. Buat state untuk melacak status loading
  bool _isLoading = false;

  // 4. Modifikasi fungsi signUp()
  void signUp(BuildContext context) async {
    // Tampilkan loading indicator
    setState(() {
      _isLoading = true;
    });

    // Validasi 1: Cek field kosong
    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua field harus diisi"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      }); // Hentikan loading
      return; // Hentikan eksekusi
    }

    // Validasi 2: Cek apakah password cocok
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password tidak cocok"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      }); // Hentikan loading
      return; // Hentikan eksekusi
    }

    // Jika semua validasi lolos, lanjutkan ke Firebase
    try {
      await _authService.signUpWithEmailPassword(
        emailController.text,
        passwordController.text,
        usernameController.text, // Kirim username
      );
      // AuthGate akan menangani navigasi jika sukses
    }
    // Tangkap error & tampilkan pesan
    on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Terjadi kesalahan"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Menangkap error umum lainnya
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 5. Selalu hentikan loading, baik sukses maupun gagal
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
      body: SafeArea(
        child: Center(
          // 6. Gunakan Stack untuk loading overlay
          child: Stack(
            children: [
              // UI Register Anda
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      width: 250, // Sesuaikan ukurannya
                      height: 250,
                      child: Image.asset(
                        'assets/images/pos_umkm.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: usernameController,
                      hintText: 'Username',
                    ),
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 15),

                    // 7. Tambahkan field Konfirmasi Password
                    CustomTextField(
                      controller: confirmPasswordController,
                      hintText: 'Konfirmasi Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 25),

                    CustomButton(
                      // 8. Nonaktifkan tombol saat loading
                      onTap: _isLoading ? null : () => signUp(context),
                      text: "Register",
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah punya akun?'),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap:
                              widget.onLoginTap, // Gunakan 'widget.onLoginTap'
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // 9. Tampilkan overlay loading
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

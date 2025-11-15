// lib/features/auth/screens/login_or_register.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart'; // 1. IMPOR FILE BARU

// 2. UBAH MENJADI STATEFULWIDGET
class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // 3. Buat state untuk mengontrol halaman
  bool showLoginPage = true;

  // 4. Buat fungsi untuk toggle
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 5. Gunakan logika if untuk menampilkan halaman
    if (showLoginPage) {
      return LoginScreen(onToggleTap: togglePages);
    } else {
      return RegisterScreen(onLoginTap: togglePages);
    }
  }
}
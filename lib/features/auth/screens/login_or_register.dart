// lib/features/auth/screens/login_or_register.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';

// File ini sekarang hanya bertugas menampilkan Halaman Login
class LoginOrRegister extends StatelessWidget {
  const LoginOrRegister({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(onRegisterTap: () {
      // Dulu ini untuk toggle, sekarang bisa kita biarkan kosong
      // atau tampilkan pesan "Hubungi admin"
    });
  }
}
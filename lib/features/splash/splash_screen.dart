// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../core/auth_gate.dart'; // Kita akan buat file ini

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Tunggu 3 detik, lalu pindah ke AuthGate
    Timer(
      const Duration(seconds: 3),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GANTI KODE LAMA ANDA DENGAN INI:
            Container(
              width: 500, // Tentukan ukuran container (sesuaikan ukurannya)
              height: 500, // Tentukan ukuran container
              child: Image.asset(
                'assets/images/ezzen.png', // Path ke logo Anda
                fit: BoxFit.contain, // Pastikan gambar pas di dalam container
              ),
            ),
            // Kita tidak perlu SizedBox lagi
            // const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

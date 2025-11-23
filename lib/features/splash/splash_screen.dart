// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../core/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 44, 126, 143), // Biru tua atas
              Color.fromARGB(255, 67, 105, 165), // Biru gelap bawah
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo bulat di tengah, bisa ganti asset PNG kamu sendiri di bawah
              Container(
                width: 350,
                height: 350,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/ezzen_logos.png', // ganti asset sesuai logo kamu
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Nama aplikasi dan tagline
              // const Text(
              //   'Point of Sale', // Ganti dengan nama kamu
              //   style: TextStyle(
              //     fontSize: 26,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.white,
              //     letterSpacing: 1.2,
              // //   ),
              // // ),
              // // const SizedBox(height: 8),
              // // Text(
              // //   'Solusi Bisnis Digital Terdepan', // Tagline bisa diganti
              // //   style: TextStyle(
              // //     fontSize: 14,
              // //     color: Colors.white.withOpacity(0.7),
              // //     fontWeight: FontWeight.w500,
              // //     letterSpacing: 0.8,
              // //   ),
              // // ),
            ],
          ),
        ),
      ),
    );
  }
}

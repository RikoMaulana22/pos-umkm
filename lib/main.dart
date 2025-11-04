// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Kita sudah tambahkan ini di pubspec
import 'firebase_options.dart';
import 'features/splash/splash_screen.dart'; // Impor Splash Screen
import 'shared/theme.dart'; // Impor Tema

// Kita akan buat CartProvider nanti saat mengerjakan fitur Kasir
// import 'features/pos/providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ganti ini saat Anda siap dengan fitur keranjang (cart)
  runApp(const MyApp());

  /*
  // Nanti, kita akan gunakan ini:
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(), // Ini untuk state keranjang
      child: const MyApp(),
    ),
  );
  */
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS UMKM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // Set background putih
      ),
      home: const SplashScreen(), // Mulai aplikasi dari Splash Screen
    );
  }
}
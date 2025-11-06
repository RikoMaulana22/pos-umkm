// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/splash/splash_screen.dart'; // Kita nonaktifkan sementara
import 'shared/theme.dart';
import 'features/pos/providers/cart_provider.dart';
//import 'features/superadmin/screens/superadmin_dashboard.dart';

// IMPOR LANGSUNG HomeScreen
//import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const MyApp(),
    ),
  );
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
        scaffoldBackgroundColor: Colors.white,
      ),

      // PERUBAHAN DI SINI:
      // Kita langsung ke HomeScreen dan memberinya ID palsu
      //home: const SuperAdminDashboard(),

      // JANGAN LUPA KEMBALIKAN KE SplashScreen NANTI:
      home: const SplashScreen(),
    );
  }
}

// lib/features/pos/screens/pos_screen.dart
import 'package:flutter/material.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kasir (Transaksi)')),
      body: const Center(
        child: Text('Halaman Kasir'),
      ),
    );
  }
}
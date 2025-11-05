// lib/features/inventory/screens/inventory_screen.dart
import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventaris (Produk)')),
      body: const Center(
        child: Text('Halaman Inventaris'),
      ),
    );
  }
}
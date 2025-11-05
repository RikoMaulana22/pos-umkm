// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final String storeId; // Terima storeId
  const SettingsScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Center(
        child: Text('Halaman Pengaturan untuk Toko ID: ${storeId}'),
      ),
    );
  }
}
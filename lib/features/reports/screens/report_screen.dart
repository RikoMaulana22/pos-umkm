// lib/features/reports/screens/report_screen.dart
import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  final String storeId; // Terima storeId
  const ReportScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: Center(
        child: Text('Halaman Laporan untuk Toko ID: ${storeId}'),
      ),
    );
  }
}
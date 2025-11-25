import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import model dan service yang sudah dibuat sebelumnya
import '../../features/superadmin/models/package_model.dart';
import '../../features/superadmin/services/package_service.dart'; // Gunakan service yang sama dengan Super Admin
import 'services/subscription_service.dart';

class SubscriptionExpiredScreen extends StatefulWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  State<SubscriptionExpiredScreen> createState() =>
      _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends State<SubscriptionExpiredScreen> {
  final PackageService _packageService = PackageService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Format Rupiah
  String formatCurrency(int amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  // Fungsi saat user memilih paket
  void _onSelectPackage(PackageModel pkg) async {
    // Tampilkan loading atau konfirmasi
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pilih ${pkg.name}?"),
        content: Text(
          "Anda akan memilih paket seharga ${formatCurrency(pkg.price)} "
          "untuk durasi ${pkg.durationDays} hari.\n\n"
          "Lanjutkan ke pembayaran?",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Lanjut")),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Ambil storeId user saat ini (Asumsi tersimpan di users collection)
        String uid = FirebaseAuth.instance.currentUser!.uid;
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        String storeId = userDoc.get('storeId');

        // Kirim Request
        await _subscriptionService.requestUpgrade(storeId, pkg.id, '');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Permintaan terkirim! Silakan lakukan pembayaran.")),
          );

          // DI SINI: Arahkan ke halaman upload bukti bayar atau Payment Gateway
          // Navigator.pushNamed(context, '/payment_instruction', arguments: pkg);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 60, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    "Masa Aktif Toko Habis",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Jangan khawatir data Anda aman. Pilih paket langganan di bawah ini untuk mengaktifkan kembali toko Anda.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // List Paket (Dynamic dari Firestore)
            Expanded(
              child: StreamBuilder<List<PackageModel>>(
                stream: _packageService.getPackages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("Tidak ada paket tersedia saat ini."));
                  }

                  final packages =
                      snapshot.data!.where((p) => p.isActive).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final pkg = packages[index];
                      // Desain Kartu Paket
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: index == 1
                                ? Colors.blue
                                : Colors.transparent, // Highlight paket tengah
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pita (Optional: Jika paket Best Seller)
                            if (index == 1)
                              Container(
                                color: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: const Text(
                                  "PALING LARIS",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Text(
                                    pkg.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    formatCurrency(pkg.price),
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).primaryColor),
                                  ),
                                  Text(
                                    "/ ${pkg.durationDays} Hari",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  // Fitur List
                                  ...pkg.features.map((feature) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.green, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(feature)),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: index == 1
                                            ? Colors.blue
                                            : Colors.grey[800],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => _onSelectPackage(pkg),
                                      child: const Text("Pilih Paket Ini",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

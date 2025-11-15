// lib/features/core/subscription_expired_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 1. HAPUS IMPOR CUSTOM_BUTTON
import 'screens/subscription_package_screen.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  final String storeId;
  // 2. TERIMA userRole
  final String userRole;
  const SubscriptionExpiredScreen({
    super.key,
    required this.storeId,
    required this.userRole, // <-- TAMBAHKAN DI CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    // 3. Tentukan apakah yang login adalah Admin
    final bool isAdmin = userRole == 'admin';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_off_outlined,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                "Langganan Habis",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              // 4. Tampilkan pesan yang berbeda untuk Admin vs Kasir
              Text(
                isAdmin
                    ? "Masa berlaku langganan Anda telah habis. Silakan perbarui paket Anda untuk melanjutkan."
                    : "Langganan toko ini telah habis. Hanya Admin/Owner yang dapat memperbaruinya. Silakan hubungi Admin Anda.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // 5. HANYA TAMPILKAN TOMBOL INI JIKA DIA ADMIN
              if (isAdmin)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SubscriptionPackageScreen(storeId: storeId),
                        ),
                      );
                    },
                    child: const Text(
                      "Lihat Pilihan Paket",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (isAdmin) const SizedBox(height: 16), // Beri jarak jika admin

              // Tombol Logout (Selalu tampil)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                  child: const Text("Logout", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

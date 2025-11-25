import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import screens
import '../auth/screens/login_or_register.dart';
import '../home/home_screen.dart';
import '../pos/screens/pos_screen.dart';
import '../superadmin/screens/superadmin_dashboard.dart';
import 'subscription_expired_screen.dart'; // Pastikan import ke screen yang benar
import '../settings/models/store_model.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // 1. Cek Auth Firebase
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!authSnapshot.hasData) {
            return const LoginOrRegister();
          }

          final User currentUser = authSnapshot.data!;

          // 2. Stream Data User (Role & StoreID)
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                FirebaseAuth.instance.signOut();
                return const LoginOrRegister();
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final String role = userData['role'] ?? 'unknown';
              final String? storeId = userData['storeId'];

              // 3. Routing Berdasarkan Role
              if (role == 'superadmin') {
                return const SuperAdminDashboard();
              }

              // Jika role Admin/Kasir tapi tidak punya StoreID
              if ((role == 'admin' || role == 'kasir') && storeId == null) {
                return const Scaffold(
                  body: Center(
                      child: Text("Error: Akun tidak terikat ke toko manapun.")),
                );
              }

              // 4. Stream Data Toko (Cek Expired & Active)
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stores')
                    .doc(storeId)
                    .snapshots(),
                builder: (context, storeSnapshot) {
                  if (storeSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                    return const Scaffold(
                      body: Center(
                          child: Text("Error: Data toko tidak ditemukan.")),
                    );
                  }

                  // Ambil data mentah untuk keamanan (hindari error parsing model jika field null)
                  final storeData = storeSnapshot.data!.data() as Map<String, dynamic>;

                  // --- LOGIKA UTAMA PERBAIKAN ---
                  
                  // A. Cek Status Aktif (Switch dari Admin)
                  // Default true jika field belum ada
                  bool isActive = storeData['isActive'] ?? true;

                  // B. Cek Tanggal Kedaluwarsa
                  bool isExpired = false;
                  if (storeData['subscriptionExpiry'] != null) {
                    Timestamp expiryTs = storeData['subscriptionExpiry'];
                    isExpired = expiryTs.toDate().isBefore(DateTime.now());
                  }

                  // Jika Toko Dinonaktifkan (Suspend) ATAU Expired -> Kunci Layar
                  if (!isActive || isExpired) {
                    return SubscriptionExpiredScreen(
                      storeId: storeId!,
                      userRole: role,
                      // Jika !isActive berarti kena Suspend
                      isSuspended: !isActive, 
                    );
                  }

                  // --- LOGIKA UTAMA SELESAI ---

                  // Jika aktif, arahkan sesuai role
                  // Ambil paket langganan untuk styling UI (Gold/Silver/Bronze)
                  String subscriptionPackage = storeData['subscriptionPackage'] ?? 'bronze';

                  if (role == 'admin') {
                    return HomeScreen(
                      storeId: storeId!,
                      subscriptionPackage: subscriptionPackage,
                    );
                  } else if (role == 'kasir') {
                    return PosScreen(
                      storeId: storeId!,
                      subscriptionPackage: subscriptionPackage,
                    );
                  }
                  return const Center(child: Text("Role tidak dikenal."));
                },
              );
            },
          );
        },
      ),
    );
  }
}
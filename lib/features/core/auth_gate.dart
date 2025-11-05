// lib/features/core/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/screens/login_or_register.dart';
import '../home/home_screen.dart';
import '../pos/screens/pos_screen.dart';
import '../superadmin/screens/superadmin_dashboard.dart';
import 'subscription_expired_screen.dart'; // <-- IMPOR HALAMAN BLOKER

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // 1. User belum login
          if (!authSnapshot.hasData) {
            return const LoginOrRegister();
          }

          // 2. User sudah login, cek rolenya di Firestore
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                // Data user tidak ada di firestore, paksa logout
                FirebaseAuth.instance.signOut(); 
                return const LoginOrRegister();
              }

              // 3. Data role ada, kita ambil
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final String role = userData['role'] ?? 'unknown';
              final String? storeId = userData['storeId'];

              // 4. LOGIKA PERAN (ROLE)
              switch (role) {
                case 'superadmin':
                  // Super Admin tidak terikat langganan
                  return const SuperAdminDashboard();

                case 'admin':
                case 'kasir':
                  // Admin dan Kasir HARUS punya storeId
                  if (storeId == null) {
                    return const Scaffold(body: Center(child: Text("Error: Akun tidak terikat ke toko.")));
                  }
                  
                  // 5. LOGIKA LANGGANAN (Subscription)
                  // Kita cek status langganan tokonya
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('stores').doc(storeId).snapshots(),
                    builder: (context, storeSnapshot) {
                      if (storeSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(body: Center(child: CircularProgressIndicator()));
                      }

                      if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                        return const Scaffold(body: Center(child: Text("Error: Toko tidak ditemukan.")));
                      }

                      final storeData = storeSnapshot.data!.data() as Map<String, dynamic>;
                      final Timestamp? expiryDate = storeData['subscriptionExpiry'];

                      // Cek jika langganan aktif
                      if (expiryDate != null && expiryDate.toDate().isAfter(DateTime.now())) {
                        // Langganan Aktif, arahkan berdasarkan role
                        if (role == 'admin') {
                          return HomeScreen(storeId: storeId);
                        } else {
                          return PosScreen(storeId: storeId);
                        }
                      } else {
                        // Langganan Habis/Tidak Ditemukan
                        return const SubscriptionExpiredScreen();
                      }
                    },
                  );
                  
                default:
                  // Role tidak dikenal
                  return const LoginOrRegister();
              }
            },
          );
        },
      ),
    );
  }
}
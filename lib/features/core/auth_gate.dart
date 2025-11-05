// lib/features/core/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/screens/login_or_register.dart';
import '../home/home_screen.dart';
import '../pos/screens/pos_screen.dart';
// Nanti kita buat: import '../superadmin/super_admin_screen.dart';

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
              
              // 3. Lagi loading data role
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // 4. Gagal ambil data role
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                // Tampilkan error atau lempar ke login
                return const LoginOrRegister(); 
              }

              // 5. Data role ada, kita arahkan
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final String role = userData['role'];
              final String? storeId = userData['storeId']; // bisa null untuk superadmin

              // Arahkan berdasarkan role
              switch (role) {
                case 'admin':
                  return HomeScreen(storeId: storeId!); // Kirim storeId ke Admin
                case 'kasir':
                  return PosScreen(storeId: storeId!); // Kirim storeId ke Kasir
                case 'superadmin':
                  // Nanti kita buat SuperAdminDashboard()
                  return const Scaffold(body: Center(child: Text("HALAMAN SUPER ADMIN")));
                default:
                  // Jika role tidak dikenal, lempar ke login
                  return const LoginOrRegister();
              }
            },
          );
        },
      ),
    );
  }
}
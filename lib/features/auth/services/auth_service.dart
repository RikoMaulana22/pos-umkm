// lib/features/auth/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Instance dari Firebase Auth & Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Fungsi Sign In (Login)
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      // Mencoba login dengan email & password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } 
    // Menangkap jika ada error
    on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 2. Fungsi Sign Up (Register)
  Future<UserCredential> signUpWithEmailPassword(String email, String password, String username) async {
    try {
      // 1. Buat user baru di Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Simpan data user (username) di koleksi 'users' di Firestore
      // Ini PENTING agar kita bisa tahu siapa nama user yang login
      _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        // Anda bisa tambahkan data lain di sini, misal: 'role': 'kasir'
      });

      return userCredential;
    } 
    // Menangkap jika ada error
    on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // 3. Fungsi Sign Out (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
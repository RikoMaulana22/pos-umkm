// lib/features/auth/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
// IMPORT MODEL
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // LOGIN EMAIL PASSWORD
  // ============================================================
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // REGISTER ADMIN + STORE (SUDAH DITAMBAH AUTO LOGOUT)
  // ============================================================
  Future<void> signUpAdminAndStore({
    required String email,
    required String password,
    required String username,
    required String storeName,
  }) async {
    UserCredential userCredential;

    // 1. Buat akun Auth
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }

    if (userCredential.user == null) {
      throw Exception("Gagal membuat akun Auth.");
    }

    // 2. Trial 30 hari
    final DateTime now = DateTime.now();
    final DateTime expiryDate = now.add(const Duration(days: 30));

    // 3. Batch: buat store + user admin
    WriteBatch batch = _firestore.batch();

    try {
      DocumentReference storeDoc = _firestore.collection('stores').doc();

      batch.set(storeDoc, {
        'name': storeName,
        'ownerId': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'subscriptionExpiry': Timestamp.fromDate(expiryDate),
        'subscriptionPrice': 0.0,
        'subscriptionPackage': 'bronze', // default paket trial
        'isActive': true,
      });

      DocumentReference userDoc =
          _firestore.collection('users').doc(userCredential.user!.uid);

      batch.set(userDoc, {
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'role': 'admin',
        'storeId': storeDoc.id,
      });

      await batch.commit();

      // ===========================================
      // 4. AUTO LOGOUT setelah signup admin
      // ===========================================
      await _auth.signOut();
    } catch (e) {
      await userCredential.user!.delete();
      throw Exception("Gagal menyimpan ke Firestore: ${e.toString()}");
    }
  }

  // ============================================================
  // CREATE CASHIER (MENGGUNAKAN TEMP FIREBASE APP)
  // ============================================================
  Future<void> createCashier({
    required String email,
    required String password,
    required String username,
    required String storeId,
  }) async {
    try {
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempApp-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      UserCredential userCredential =
          await FirebaseAuth.instanceFor(app: tempApp)
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await tempApp.delete();

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'role': 'kasir',
        'storeId': storeId,
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // GET LIST KASIR
  // ============================================================
  Stream<List<UserModel>> getCashiers(String storeId) {
    return _firestore
        .collection('users')
        .where('storeId', isEqualTo: storeId)
        .where('role', isEqualTo: 'kasir')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<UserModel>> getStoreUsersForFilter(String storeId) {
    return _firestore
        .collection('users')
        .where('storeId', isEqualTo: storeId)
        // Ambil semua role di toko itu
        .where('role', whereIn: ['admin', 'manager', 'kasir'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  // ============================================================
  // DELETE KASIR
  // ============================================================
  Future<void> deleteCashier(String uid) async {
    try {
      // Cukup hapus dokumen user di Firestore.
      // INI ADALAH CARA YANG BENAR.
      // Jangan mencoba menghapus akun Auth milik kasir.
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception("Gagal menghapus kasir: ${e.toString()}");
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

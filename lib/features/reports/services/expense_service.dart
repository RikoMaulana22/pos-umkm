import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tambah Pengeluaran Baru
  Future<void> addExpense({
    required String storeId,
    required double amount,
    required String category,
    required String note,
    required DateTime date,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("User tidak login");

    await _firestore.collection('expenses').add({
      'storeId': storeId,
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Hapus Pengeluaran
  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  // Ambil Data Pengeluaran (Stream)
  Stream<List<ExpenseModel>> getExpenses(String storeId, {int days = 30}) {
    final DateTime now = DateTime.now();
    final DateTime startDate = now.subtract(Duration(days: days));

    return _firestore
        .collection('expenses')
        .where('storeId', isEqualTo: storeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    });
  }
}
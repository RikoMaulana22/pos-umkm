// lib/features/pos/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<String> processTransaction({
    required CartProvider cart,
    required String storeId,
    required String paymentMethod, double? cashReceived, double? change, required String customerName,
  }) async {
    if (_userId == null) throw Exception("User tidak login");

    // Dapatkan referensi ke database
    WriteBatch batch = _firestore.batch();
    
    // 1. Buat dokumen transaksi baru
    DocumentReference transactionDoc = _firestore.collection('transactions').doc();

    // Siapkan data item untuk disimpan
    List<Map<String, dynamic>> itemsData = cart.items.entries.map((entry) {
      final item = entry.value;
      return {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'price': item.product.hargaJual,
      };
    }).toList();

    // Simpan data transaksi
    batch.set(transactionDoc, {
      'storeId': storeId,
      'cashierId': _userId,
      'totalPrice': cart.totalPrice,
      'totalItems': cart.totalItems,
      'paymentMethod': paymentMethod,
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Kurangi stok setiap produk di keranjang
    for (var item in cart.items.values) {
      DocumentReference productDoc =
          _firestore.collection('products').doc(item.product.id);
      
      // Kurangi stok dengan 'FieldValue.increment'
      batch.update(productDoc, {
        'stok': FieldValue.increment(-item.quantity), 
      });
    }

    try {
      // 3. Jalankan semua operasi (Simpan Transaksi & Update Stok)
      await batch.commit();
      return transactionDoc.id; // Kembalikan ID transaksi jika sukses
    } catch (e) {
      throw Exception("Gagal memproses transaksi: ${e.toString()}");
    }
  }
}
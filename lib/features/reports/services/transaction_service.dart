// lib/features/pos/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../pos/providers/cart_provider.dart';
import '../../reports/models/transaction_item_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<String> processTransaction({
    required CartProvider cart,
    required String storeId,
    required String paymentMethod,
    // INI ADALAH BAGIAN YANG MEMPERBAIKI ERROR ANDA
    double? cashReceived,
    double? change,
  }) async {
    if (_userId == null) throw Exception("User tidak login");

    WriteBatch batch = _firestore.batch();
    DocumentReference transactionDoc =
        _firestore.collection('transactions').doc();

    // 4. UBAH Logika penyimpanan item
    List<Map<String, dynamic>> itemsData = cart.items.entries.map((entry) {
      // Buat model item transaksi
      final item = entry.value;
      final transactionItem = TransactionItemModel(
        productId: item.product.id!,
        productName: item.product.name,
        quantity: item.quantity,
        price: item.product.hargaJual,
        cost: item.product.hargaModal, // <-- INI KUNCINYA
      );
      return transactionItem.toMap(); // Konversi ke Map
    }).toList();

    // 5. SIMPAN data transaksi lengkap
    batch.set(transactionDoc, {
      'storeId': storeId,
      'cashierId': _userId,
      'totalPrice': cart.totalPrice,
      'totalItems': cart.totalItems,
      'paymentMethod': paymentMethod,
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
      'cashReceived': cashReceived, // Simpan uang tunai
      'change': change, // Simpan kembalian
    });

    // 2. Kurangi stok (Tidak berubah)
    for (var item in cart.items.values) {
      DocumentReference productDoc =
          _firestore.collection('products').doc(item.product.id);

      batch.update(productDoc, {
        'stok': FieldValue.increment(-item.quantity),
      });
    }

    try {
      await batch.commit();
      return transactionDoc.id;
    } catch (e) {
      throw Exception("Gagal memproses transaksi: ${e.toString()}");
    }
  }
}

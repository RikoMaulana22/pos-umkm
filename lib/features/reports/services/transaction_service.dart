// lib/features/pos/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:erp_umkm/features/pos/providers/cart_provider.dart';
class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<String> processTransaction({
    required CartProvider cart,
    required String storeId,
    required String paymentMethod,
    double? cashReceived,
    String? customerName, // Parameter baru
  }) async {
    if (_userId == null) throw Exception("User tidak login");

    WriteBatch batch = _firestore.batch();
    DocumentReference transactionDoc = _firestore.collection('transactions').doc();

    // --- LOGIKA HITUNG HUTANG & STATUS ---
    double total = cart.totalPrice;
    double paid = 0;
    double debt = 0;
    String status = 'Lunas';

    if (paymentMethod == 'Hutang') {
      paid = 0;
      debt = total;
      status = 'Belum Lunas';
    } else if (paymentMethod == 'Split') {
      paid = cashReceived ?? 0;
      debt = total - paid;
      // Jika pembayaran >= total, anggap lunas (kembalian diurus UI)
      if (debt <= 0) {
        debt = 0;
        paid = total;
        status = 'Lunas';
      } else {
        status = 'Sebagian';
      }
    } else {
      // Tunai, QRIS, Transfer, Kartu
      paid = total;
      debt = 0;
      status = 'Lunas';
    }

    // --- PERSIAPAN DATA ---
    List<Map<String, dynamic>> itemsData = cart.items.entries.map((entry) {
      final item = entry.value;
      return {
        'productId': item.product.id,
        'productName': item.product.name,
        'quantity': item.quantity,
        'price': item.product.hargaJual,
        'cost': item.product.hargaModal, // Penting untuk laporan laba
      };
    }).toList();

    // 1. Simpan Transaksi Utama
    batch.set(transactionDoc, {
      'storeId': storeId,
      'cashierId': _userId,
      'totalPrice': total,
      'totalItems': cart.totalItems,
      'paymentMethod': paymentMethod,
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
      // Field Baru
      'paid': paid,
      'debt': debt,
      'customerName': customerName,
      'paymentStatus': status,
    });

    // 2. Jika ada hutang, catat di koleksi 'debts'
    if (debt > 0) {
      DocumentReference debtDoc = _firestore.collection('debts').doc();
      batch.set(debtDoc, {
        'transactionId': transactionDoc.id,
        'customerName': customerName,
        'storeId': storeId,
        'originalTotal': total,
        'amountPaid': paid,
        'remainingAmount': debt,
        'status': status == 'Belum Lunas' ? 'unpaid' : 'partial',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    // 3. Kurangi Stok
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
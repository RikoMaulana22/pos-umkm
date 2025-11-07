import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double hargaModal;
  final double hargaJual;
  final int stok;
  final String? imageUrl;
  final String createdBy;
  final DateTime? timestamp; // ✅ Menyimpan waktu penambahan produk

  Product({
    this.id = '',
    required this.name,
    required this.hargaModal,
    required this.hargaJual,
    required this.stok,
    this.imageUrl,
    required this.createdBy,
    this.timestamp,
  });

  /// ✅ Convert Product object → Map (untuk disimpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'hargaModal': hargaModal,
      'hargaJual': hargaJual,
      'stok': stok,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      // Gunakan serverTimestamp agar waktu sinkron dengan server Firestore
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  /// ✅ Convert Map → Product object (saat dibaca dari Firestore)
  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      hargaModal: (data['hargaModal'] ?? 0).toDouble(),
      hargaJual: (data['hargaJual'] ?? 0).toDouble(),
      stok: (data['stok'] ?? 0).toInt(),
      imageUrl: data['imageUrl'] as String?,
      createdBy: data['createdBy'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
    );
  }
}

// lib/features/inventory/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String name;
  final double hargaModal; // Harga Beli
  final double hargaJual;  // Harga Jual
  final int stok;
  final String? imageUrl;
  final String createdBy; // Untuk melacak siapa yang menambah produk

  Product({
    this.id,
    required this.name,
    required this.hargaModal,
    required this.hargaJual,
    required this.stok,
    this.imageUrl,
    required this.createdBy,
  });

  // Mengubah Map (dari Firestore) menjadi objek Product
  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      hargaModal: (map['hargaModal'] ?? 0).toDouble(),
      hargaJual: (map['hargaJual'] ?? 0).toDouble(),
      stok: map['stok'] ?? 0,
      imageUrl: map['imageUrl'],
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Mengubah objek Product menjadi Map (untuk dikirim ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'hargaModal': hargaModal,
      'hargaJual': hargaJual,
      'stok': stok,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'timestamp': FieldValue.serverTimestamp(), // Menambah stempel waktu
    };
  }
}

// lib/features/inventory/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// 1. IMPOR MODEL BARU
import 'product_variant_model.dart';

class Product {
  final String id;
  final String name;
  final String? imageUrl;
  final String createdBy;
  final DateTime? timestamp;
  final String? categoryId;
  final String? categoryName;

  // --- ATRIBUT BARU UNTUK VARIAN ---
  final bool isVariantProduct; // Penanda apakah ini produk bervarian
  final List<ProductVariant>
      variants; // Daftar varian jika isVariantProduct = true

  // --- ATRIBUT LAMA (untuk Produk Simpel) ---
  final double hargaModal;
  final double hargaJual;
  final int stok;
  final double? hargaDiskon;
  final String? sku;

  Product({
    this.id = '',
    required this.name,
    this.imageUrl,
    required this.createdBy,
    this.timestamp,
    this.categoryId,
    this.categoryName,

    // 2. TAMBAHKAN FIELD BARU DI CONSTRUCTOR
    this.isVariantProduct = false,
    this.variants = const [],

    // 3. JADIKAN FIELD LAMA OPSIONAL (default 0)
    this.hargaModal = 0,
    this.hargaJual = 0,
    this.stok = 0,
    this.hargaDiskon,
    this.sku,
  });

  // 4. UBAH HELPER HARGA FINAL
  // Ini akan mengambil harga produk simpel
  double get hargaJualFinal {
    if (isVariantProduct) {
      // Jika produk bervarian, harga ini tidak relevan
      // Kita bisa tampilkan rentang harga, misal "Mulai dari Rp 10.000"
      return variants
          .map((v) => v.hargaJualFinal)
          .fold(0.0, (a, b) => a < b ? a : b);
    }
    // Logika lama untuk produk simpel
    if (hargaDiskon != null && hargaDiskon! > 0 && hargaDiskon! < hargaJual) {
      return hargaDiskon!;
    }
    return hargaJual;
  }

  // 5. HELPER BARU UNTUK STOK
  // Menjumlahkan stok semua varian, atau stok simpel
  int get totalStok {
    if (isVariantProduct) {
      return variants.fold(0, (sum, v) => sum + v.stok);
    }
    return stok;
  }

  /// Convert Product object → Map (untuk disimpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'timestamp': FieldValue.serverTimestamp(),
      'categoryId': categoryId,
      'categoryName': categoryName,

      // 6. SIMPAN DATA VARIAN BARU
      'isVariantProduct': isVariantProduct,
      // Simpan list of variants sebagai list of maps
      'variants': variants.map((v) => v.toMap()).toList(),

      // 7. SIMPAN DATA PRODUK SIMPEL
      'hargaModal': hargaModal,
      'hargaJual': hargaJual,
      'stok': stok,
      'hargaDiskon': hargaDiskon,
      'sku': sku,
    };
  }

  /// Convert Map → Product object (saat dibaca dari Firestore)
  factory Product.fromMap(Map<String, dynamic> data, String id) {
    // 8. BACA DATA VARIAN DARI FIRESTORE
    List<ProductVariant> productVariants = [];
    if (data['variants'] != null) {
      for (var v in data['variants'] as List) {
        productVariants.add(ProductVariant.fromMap(v as Map<String, dynamic>));
      }
    }

    return Product(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdBy: data['createdBy'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      categoryId: data['categoryId'],
      categoryName: data['categoryName'],

      // 9. ISI FIELD VARIAN BARU
      isVariantProduct: data['isVariantProduct'] ?? false,
      variants: productVariants,

      // 10. ISI FIELD PRODUK SIMPEL
      hargaModal: (data['hargaModal'] ?? 0).toDouble(),
      hargaJual: (data['hargaJual'] ?? 0).toDouble(),
      stok: (data['stok'] ?? 0).toInt(),
      hargaDiskon: data['hargaDiskon'] as double?,
      sku: data['sku'] as String?,
    );
  }
}

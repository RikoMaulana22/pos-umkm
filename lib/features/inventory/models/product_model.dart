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
  double get hargaJualFinal {
    if (isVariantProduct) {
      return variants
          .map((v) => v.hargaJualFinal)
          .fold(0.0, (a, b) => a < b ? a : b);
    }
    if (hargaDiskon != null && hargaDiskon! > 0 && hargaDiskon! < hargaJual) {
      return hargaDiskon!;
    }
    return hargaJual;
  }

  // 5. HELPER BARU UNTUK STOK
  int get totalStok {
    if (isVariantProduct) {
      return variants.fold(0, (sum, v) => sum + v.stok);
    }
    return stok;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'timestamp': FieldValue.serverTimestamp(),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isVariantProduct': isVariantProduct,
      'variants': variants.map((v) => v.toMap()).toList(),
      'hargaModal': hargaModal,
      'hargaJual': hargaJual,
      'stok': stok,
      'hargaDiskon': hargaDiskon,
      'sku': sku,
    };
  }

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
      isVariantProduct: data['isVariantProduct'] ?? false,
      variants: productVariants,
      hargaModal: (data['hargaModal'] as num?)?.toDouble() ?? 0.0,
      hargaJual: (data['hargaJual'] as num?)?.toDouble() ?? 0.0,
      stok: (data['stok'] as num?)?.toInt() ?? 0,
      hargaDiskon: (data['hargaDiskon'] as num?)?.toDouble(),
      sku: data['sku'] as String?,
    );
  }
}

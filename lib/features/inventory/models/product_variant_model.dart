// lib/features/inventory/models/product_variant_model.dart

// Model ini akan menyimpan data untuk SATU varian
// (Contoh: "Besar", Rp 15.000, Stok 50, SKU "NG-BSR")
class ProductVariant {
  final String id; // ID unik untuk varian, bisa pakai NIK
  final String name; // Nama varian (mis. "Besar", "Merah", "Pedas")
  final double hargaModal;
  final double hargaJual;
  final double? hargaDiskon;
  int stok;
  final String? sku;

  ProductVariant({
    required this.id,
    required this.name,
    required this.hargaModal,
    required this.hargaJual,
    required this.stok,
    this.hargaDiskon,
    this.sku,
  });

  // Helper untuk harga final
  double get hargaJualFinal {
    if (hargaDiskon != null && hargaDiskon! > 0 && hargaDiskon! < hargaJual) {
      return hargaDiskon!;
    }
    return hargaJual;
  }

  // Konversi dari Map (saat dibaca dari Firestore)
  factory ProductVariant.fromMap(Map<String, dynamic> data) {
    return ProductVariant(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: data['name'] ?? '',
      hargaModal: (data['hargaModal'] ?? 0.0).toDouble(),
      hargaJual: (data['hargaJual'] ?? 0.0).toDouble(),
      hargaDiskon: (data['hargaDiskon'] as double?),
      stok: (data['stok'] ?? 0).toInt(),
      sku: data['sku'] as String?,
    );
  }

  // Konversi ke Map (saat disimpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hargaModal': hargaModal,
      'hargaJual': hargaJual,
      'hargaDiskon': hargaDiskon,
      'stok': stok,
      'sku': sku,
    };
  }
}

// lib/features/pos/models/cart_item_model.dart
import '../../inventory/models/product_model.dart';
// 1. IMPOR MODEL VARIAN
import '../../inventory/models/product_variant_model.dart';

class CartItem {
  final Product product;
  // 2. TAMBAHKAN VARIAN (bisa null jika produk simpel)
  final ProductVariant? variant;
  int quantity;

  // 3. BUAT ID UNIK UNTUK KERANJANG
  // Ini akan jadi "product_id" (untuk produk simpel)
  // atau "product_id_variant_id" (untuk produk bervarian)
  final String cartId;

  CartItem({
    required this.product,
    this.variant, // 4. Tambah di constructor
    this.quantity = 1,
  }) : cartId = product.id +
            (variant != null ? '_${variant.id}' : ''); // 5. Buat ID unik

  // 6. UBAH LOGIKA TOTAL HARGA
  // Ambil harga dari varian jika ada, jika tidak, ambil dari produk
  double get totalPrice {
    final double price = variant?.hargaJualFinal ?? product.hargaJualFinal;
    return price * quantity;
  }
}

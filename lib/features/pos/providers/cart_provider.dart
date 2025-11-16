// lib/features/pos/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../../inventory/models/product_model.dart';
import '../models/cart_item_model.dart';
// 1. IMPOR MODEL VARIAN
import '../../inventory/models/product_variant_model.dart';

class CartProvider with ChangeNotifier {
  // 2. Kunci (String) sekarang adalah cartId (bukan lagi productId)
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get totalItems {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalPrice {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  // 3. MODIFIKASI FUNGSI addItem
  void addItem(Product product, [ProductVariant? variant]) {
    // 4. Buat cartId unik
    final cartId = product.id + (variant != null ? '_${variant.id}' : '');

    if (_items.containsKey(cartId)) {
      // Jika sudah ada (misal: 2x Kopi Besar), tambah jumlahnya
      _items.update(
        cartId,
        (existingItem) => CartItem(
          product: existingItem.product,
          variant: existingItem.variant,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      // Jika item baru, tambahkan ke keranjang
      _items.putIfAbsent(
        cartId,
        () => CartItem(
          product: product,
          variant: variant,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  // 5. MODIFIKASI FUNGSI decreaseItem
  void decreaseItem(CartItem item) {
    final cartId = item.cartId; // Gunakan cartId
    if (!_items.containsKey(cartId)) return;

    if (_items[cartId]!.quantity > 1) {
      _items.update(
        cartId,
        (existingItem) => CartItem(
          product: existingItem.product,
          variant: existingItem.variant,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      // Jika sisa 1, hapus
      _items.remove(cartId);
    }
    notifyListeners();
  }

  // 6. MODIFIKASI FUNGSI getQuantity
  int getQuantity(Product product, [ProductVariant? variant]) {
    final cartId = product.id + (variant != null ? '_${variant.id}' : '');
    return _items[cartId]?.quantity ?? 0;
  }

  void clearCart() {
    _items = {};
    notifyListeners();
  }
}

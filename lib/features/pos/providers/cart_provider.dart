// lib/features/pos/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../../inventory/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Hitung total item di keranjang
  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Hitung total harga di keranjang
  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Logika untuk menambah item ke keranjang
  void addItem(Product product) {
    // Cek apakah produk sudah ada di keranjang
    for (var item in _items) {
      if (item.product.id == product.id) {
        // Cek apakah stok masih ada
        if (item.quantity < product.stok) {
          item.quantity++;
          notifyListeners(); // Beri tahu UI untuk update
        }
        return; // Selesai
      }
    }

    // Jika produk belum ada di keranjang, tambahkan sebagai item baru
    if (product.stok > 0) {
      _items.add(CartItem(product: product, quantity: 1));
      notifyListeners(); // Beri tahu UI untuk update
    }
  }

  // Logika untuk mengurangi item dari keranjang
  void decreaseItem(CartItem cartItem) {
    if (cartItem.quantity > 1) {
      cartItem.quantity--;
    } else {
      _items.remove(cartItem);
    }
    notifyListeners();
  }

  // Logika untuk menghapus item dari keranjang
  void removeItem(CartItem cartItem) {
    _items.remove(cartItem);
    notifyListeners();
  }

  // Mengosongkan keranjang
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
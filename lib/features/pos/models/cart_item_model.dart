// lib/features/pos/models/cart_item_model.dart
import '../../inventory/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.hargaJual * quantity;
}
// lib/features/pos/widgets/cart_details_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../screens/payment_screen.dart';
import '../../../shared/theme.dart';

class CartDetailsSheet extends StatelessWidget {
  final String storeId;
  final String subscriptionPackage;

  const CartDetailsSheet({
    super.key,
    required this.storeId,
    required this.subscriptionPackage,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Keranjang (${cart.totalItems} item)",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (cart.items.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      cart.clearCart();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    label: const Text("Hapus Semua",
                        style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
          const Divider(thickness: 1),

          // List produk
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("Keranjang kosong",
                            style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final cartItem = cart.items[index];
                      return Row(
                        children: [
                          // Gambar produk
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              image: (cartItem.product.imageUrl != null)
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          cartItem.product.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (cartItem.product.imageUrl == null)
                                ? const Icon(Icons.inventory,
                                    color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Nama + harga
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cartItem.product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(
                                  formatCurrency
                                      .format(cartItem.product.hargaJual),
                                  style: const TextStyle(color: primaryColor),
                                ),
                              ],
                            ),
                          ),

                          // Tombol +/-
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () => cart.decreaseItem(cartItem),
                                  color: Colors.grey[800],
                                ),
                                Text(
                                  cartItem.quantity.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () {
                                    if (cartItem.quantity <
                                        cartItem.product.stok) {
                                      cart.addItem(cartItem.product);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text("Stok maksimum tercapai!"),
                                        duration: Duration(milliseconds: 500),
                                      ));
                                    }
                                  },
                                  color: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Total + tombol checkout
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Pembayaran",
                            style: TextStyle(fontSize: 16)),
                        Text(
                          formatCurrency.format(cart.totalPrice),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                storeId: storeId,
                                subscriptionPackage: subscriptionPackage,
                              ),
                            ),
                          );
                        },
                        child: const Text("Lanjut ke Pembayaran",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

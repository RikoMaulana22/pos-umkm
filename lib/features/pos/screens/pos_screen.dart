// lib/features/pos/screens/pos_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../inventory/services/inventory_service.dart';
import '../../inventory/models/product_model.dart';
import '../../../shared/theme.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_details_sheet.dart'; // <-- Pastikan impor ini ada
import '../widgets/product_card.dart';

class PosScreen extends StatelessWidget {
  final String storeId;
  const PosScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final InventoryService _inventoryService = InventoryService();
    final bool isCashier = FirebaseAuth.instance.currentUser != null;
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir (Transaksi)'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isCashier)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _inventoryService.getProducts(storeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada produk."));
                }

                final products = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                );
              },
            ),
          ),
          
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: cart.items.isEmpty ? 0 : 90,
                child: cart.items.isEmpty ? null : GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => CartDetailsSheet(storeId: storeId), // <-- Kirim storeId
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, -5),
                        ),
                      ],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: Text("${cart.totalItems}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Total", style: TextStyle(color: Colors.white70, fontSize: 14)),
                                Text(
                                  formatCurrency.format(cart.totalPrice),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Text("Lihat Keranjang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_up, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
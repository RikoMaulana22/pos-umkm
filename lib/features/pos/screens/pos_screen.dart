// lib/features/pos/screens/pos_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../inventory/services/inventory_service.dart';
import '../../inventory/models/product_model.dart';
import '../../../shared/theme.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_details_sheet.dart';
import '../widgets/product_card.dart';

// Category
import '../../inventory/models/category_model.dart';
import '../../inventory/services/category_service.dart';

class PosScreen extends StatefulWidget {
  final String storeId;

  // 🔥 Tambahkan subscription di file baru
  final String subscriptionPackage;

  const PosScreen({
    super.key,
    required this.storeId,
    required this.subscriptionPackage,
  });

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final InventoryService _inventoryService = InventoryService();
  final CategoryService _categoryService = CategoryService();
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

  String? _selectedCategoryId;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCashier = FirebaseAuth.instance.currentUser != null;

    final cartButton = Consumer<CartProvider>(
      builder: (context, cart, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: cart.items.isEmpty ? 0 : 90,
          child: cart.items.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => CartDetailsSheet(
                        storeId: widget.storeId,
                        // 🔥 Kirim subscription ke CartDetails
                        subscriptionPackage: widget.subscriptionPackage,
                      ),
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle),
                              child: Text("${cart.totalItems}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Total",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                                Text(
                                  formatCurrency.format(cart.totalPrice),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Text("Lihat Keranjang",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
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
    );

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
          _buildCategoryFilter(),

          // 🔥 Search Bar ditambahkan ke versi lama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari produk...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _inventoryService.getProducts(
                widget.storeId,
                categoryId: _selectedCategoryId,
              ),
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

                final filtered = products.where((p) {
                  return p.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("Produk tidak ditemukan."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: filtered[index]);
                  },
                );
              },
            ),
          ),

          cartButton,
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: StreamBuilder<List<Category>>(
        stream: _categoryService.getCategories(widget.storeId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text("Memuat kategori..."));
          }

          final categories = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip(
                  label: "Semua",
                  isSelected: _selectedCategoryId == null,
                  onTap: () => setState(() => _selectedCategoryId = null),
                );
              }

              final category = categories[index - 1];

              return _buildCategoryChip(
                label: category.name,
                isSelected: _selectedCategoryId == category.id,
                onTap: () => setState(() => _selectedCategoryId = category.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : primaryColor,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: isSelected ? primaryColor : Colors.white,
        side: BorderSide(color: isSelected ? primaryColor : Colors.grey[300]!),
        onPressed: onTap,
      ),
    );
  }
}

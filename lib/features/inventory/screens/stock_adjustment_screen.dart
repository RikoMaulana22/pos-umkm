// lib/features/inventory/screens/stock_adjustment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme.dart';
import '../models/product_model.dart';
import '../services/inventory_service.dart';

class StockAdjustmentScreen extends StatefulWidget {
  final String storeId;
  const StockAdjustmentScreen({super.key, required this.storeId});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final InventoryService _inventoryService = InventoryService();
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

  void _showAdjustStockDialog(Product product) {
    final TextEditingController adjController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Sesuaikan Stok: ${product.name}"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Stok saat ini: ${product.stok}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: adjController,
                  decoration: const InputDecoration(
                    labelText: "Jumlah Penyesuaian",
                    hintText: "Contoh: 10 (tambah) atau -5 (kurang)",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Jumlah tidak boleh kosong";
                    }
                    final int? amount = int.tryParse(value);
                    if (amount == null) {
                      return "Angka tidak valid";
                    }
                    if (amount == 0) {
                      return "Jumlah tidak boleh nol";
                    }
                    if ((product.stok + amount) < 0) {
                      return "Stok akhir tidak boleh negatif";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final int amount = int.parse(adjController.text);
                  try {
                    await _inventoryService.adjustStock(product.id!, amount);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Stok ${product.name} berhasil disesuaikan"),
                      backgroundColor: Colors.green,
                    ));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Gagal: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penyesuaian Stok'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari produk...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _inventoryService.getProducts(widget.storeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada produk."));
                }

                // Filter produk berdasarkan pencarian
                final products = snapshot.data!.where((product) {
                  return product.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (products.isEmpty) {
                  return const Center(child: Text("Produk tidak ditemukan."));
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text("Kategori: ${product.categoryName ?? 'N/A'}"),
                        trailing: Text(
                          "Stok: ${product.stok}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _showAdjustStockDialog(product),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
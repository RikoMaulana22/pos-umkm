// lib/features/pos/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../inventory/models/product_model.dart';
import '../providers/cart_provider.dart';
import '../../../shared/theme.dart';
// 1. IMPOR DIALOG BARU
import 'variant_selection_dialog.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // 2. LOGIKA PENGECEKAN KERANJANG BERUBAH
        // Kita cek berdasarkan produk ID saja untuk badge,
        // karena kita tidak tahu varian mana yang ada di keranjang
        final int quantityInCart = cart.items.values
            .where((item) => item.product.id == product.id)
            .fold(0, (sum, item) => sum + item.quantity);

        final bool isInCart = quantityInCart > 0;

        // Cek diskon (hanya untuk produk simpel)
        final bool hasDiscount = !product.isVariantProduct &&
            (product.hargaDiskon != null &&
                product.hargaDiskon! > 0 &&
                product.hargaDiskon! < product.hargaJual);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isInCart
                ? BorderSide(color: primaryColor, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // 3. LOGIKA ONTAP BERUBAH TOTAL
            onTap: () {
              // Cek stok total
              if (product.totalStok <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Stok produk ini habis!"),
                    backgroundColor: Colors.red));
                return;
              }

              if (product.isVariantProduct) {
                // JIKA PRODUK BERVARIAN: Tampilkan dialog
                showDialog(
                  context: context,
                  builder: (ctx) => VariantSelectionDialog(product: product),
                );
              } else {
                // JIKA PRODUK SIMPEL: Langsung tambahkan
                cart.addItem(product, null); // Kirim null untuk varian
              }
            },
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Produk
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: (product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty)
                            ? Image.network(product.imageUrl!,
                                fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                      ),
                    ),
                    // Info Produk
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // 4. LOGIKA HARGA BERUBAH
                          if (product.isVariantProduct)
                            // Tampilkan "Mulai dari..."
                            Text(
                              "Mulai ${formatCurrency.format(product.hargaJualFinal)}",
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            )
                          else if (hasDiscount)
                            // Tampilkan harga diskon (produk simpel)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatCurrency.format(product.hargaJual),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  formatCurrency.format(product.hargaJualFinal),
                                  style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            )
                          else
                            // Tampilkan harga normal (produk simpel)
                            Text(
                              formatCurrency.format(product.hargaJualFinal),
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),

                          // 5. TAMPILKAN STOK TOTAL
                          Text(
                            "Stok: ${product.totalStok}",
                            style: TextStyle(
                                fontSize: 12,
                                color: product.totalStok < 5
                                    ? Colors.red
                                    : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Badge keranjang (logika tidak berubah)
                if (isInCart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        quantityInCart.toString(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// lib/features/pos/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../inventory/models/product_model.dart';
import '../providers/cart_provider.dart';
import '../../../shared/theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    // Gunakan 'Consumer' agar HANYA kartu ini yang rebuild saat cart berubah
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final int quantityInCart = cart.getQuantity(product.id);
        final bool isInCart = quantityInCart > 0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            // Beri border hijau jika ada di keranjang
            side: isInCart
                ? BorderSide(color: primaryColor, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (product.stok > 0) {
                cart.addItem(product);
                // Opsional: Hapus SnackBar jika ingin lebih cepat
                // ScaffoldMessenger.of(context).hideCurrentSnackBar();
                // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.name} +1"), duration: Duration(milliseconds: 500)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Stok habis!"), backgroundColor: Colors.red));
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
                        child: (product.imageUrl != null)
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
                          Text(
                            formatCurrency.format(product.hargaJual),
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Stok: ${product.stok}",
                            style: TextStyle(
                                fontSize: 12,
                                color: product.stok < 5
                                    ? Colors.red
                                    : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Indikator Jumlah di Keranjang (Badge)
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

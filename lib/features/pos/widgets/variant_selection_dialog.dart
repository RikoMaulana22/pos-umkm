// lib/features/pos/widgets/variant_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme.dart';
import '../../inventory/models/product_model.dart';
import '../../inventory/models/product_variant_model.dart';
import '../providers/cart_provider.dart';

class VariantSelectionDialog extends StatelessWidget {
  final Product product;
  const VariantSelectionDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Pilih Varian - ${product.name}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey[500],
                ),
              ],
            ),
            const Divider(height: 24),

            // Daftar Varian
            // Kita gunakan Flexible agar bisa di-scroll jika varian terlalu banyak
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: product.variants.length,
                itemBuilder: (context, index) {
                  final variant = product.variants[index];
                  final bool isStokHabis = variant.stok <= 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      title: Text(
                        variant.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isStokHabis ? Colors.grey[500] : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "Stok: ${variant.stok}",
                        style: TextStyle(
                          color: isStokHabis ? Colors.red : Colors.grey[600],
                        ),
                      ),
                      trailing: Text(
                        formatCurrency.format(variant.hargaJualFinal),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isStokHabis ? Colors.grey[500] : primaryColor,
                        ),
                      ),
                      onTap: isStokHabis
                          ? null // Nonaktifkan tombol jika stok habis
                          : () {
                              // Tambahkan varian ini ke keranjang
                              Provider.of<CartProvider>(context, listen: false)
                                  .addItem(product, variant);
                              // Tutup dialog
                              Navigator.pop(context);
                            },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

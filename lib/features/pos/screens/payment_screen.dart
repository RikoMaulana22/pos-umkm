// lib/features/pos/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/transaction_service.dart';
import 'receipt_screen.dart'; // Halaman struk (Langkah 4)
import '../../../shared/theme.dart';

class PaymentScreen extends StatefulWidget {
  final String storeId;
  const PaymentScreen({super.key, required this.storeId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = false;

  void _confirmPayment() async {
    setState(() { _isLoading = true; });
    final cart = Provider.of<CartProvider>(context, listen: false);

    try {
      // Panggil service untuk proses transaksi
      final String transactionId = await _transactionService.processTransaction(
        cart: cart,
        storeId: widget.storeId,
        paymentMethod: "QRIS", // Sesuai desain
      );

      // Jika sukses, pindah ke halaman Struk
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(
            transactionId: transactionId,
          ),
        ),
      );
      
      // Kosongkan keranjang
      cart.clearCart();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data keranjang dari Provider
    final cart = Provider.of<CartProvider>(context, listen: false);
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Total Pembayaran",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                Text(
                  formatCurrency.format(cart.totalPrice),
                  style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: primaryColor),
                ),
                const SizedBox(height: 30),
                
                // Tampilkan gambar QRIS Anda
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/qris_placeholder.png', // Sesuaikan nama file
                    width: 250,
                  ),
                ),
                const SizedBox(height: 30),
                
                Text(
                  "Scan QRIS untuk membayar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                
                // Tombol Konfirmasi dan Batal
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmPayment,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Konfirmasi"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
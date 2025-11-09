// lib/features/pos/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/transaction_service.dart';
import 'receipt_screen.dart';
import '../../../shared/theme.dart';

class PaymentScreen extends StatefulWidget {
  final String storeId;
  const PaymentScreen({super.key, required this.storeId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _cashController = TextEditingController();
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

  bool _isLoading = false;
  String _paymentMethod = "QRIS"; // "QRIS" atau "Tunai"
  double _cashReceived = 0.0;
  double _change = 0.0;

  late double _totalPrice;

  @override
  void initState() {
    super.initState();
    // Ambil total harga sekali saja
    _totalPrice = Provider.of<CartProvider>(context, listen: false).totalPrice;

    _cashController.addListener(_calculateChange);
  }

  void _calculateChange() {
    setState(() {
      _cashReceived = double.tryParse(_cashController.text) ?? 0.0;
      if (_cashReceived > 0 && _cashReceived >= _totalPrice) {
        _change = _cashReceived - _totalPrice;
      } else {
        _change = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _cashController.removeListener(_calculateChange);
    _cashController.dispose();
    super.dispose();
  }

  void _confirmPayment() async {
    // Validasi untuk tunai
    if (_paymentMethod == "Tunai" && _cashReceived < _totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Jumlah uang tunai tidak mencukupi"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final cart = Provider.of<CartProvider>(context, listen: false);

    try {
      final String transactionId = await _transactionService.processTransaction(
        cart: cart,
        storeId: widget.storeId,
        paymentMethod: _paymentMethod,
        cashReceived: _paymentMethod == "Tunai" ? _cashReceived : null,
        change: _paymentMethod == "Tunai" ? _change : null,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(
            transactionId: transactionId,
          ),
        ),
      );

      cart.clearCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canConfirm =
        !(_paymentMethod == "Tunai" && _cashReceived < _totalPrice);

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
              children: [
                const Text(
                  "Total Pembayaran",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                Text(
                  formatCurrency.format(_totalPrice),
                  style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: primaryColor),
                ),
                const SizedBox(height: 24),

                // Toggle Pilihan Pembayaran
                ToggleButtons(
                  isSelected: [
                    _paymentMethod == "QRIS",
                    _paymentMethod == "Tunai"
                  ],
                  onPressed: (index) {
                    setState(() {
                      _paymentMethod = index == 0 ? "QRIS" : "Tunai";
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: primaryColor,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(children: [
                        Icon(Icons.qr_code),
                        SizedBox(width: 8),
                        Text("QRIS")
                      ]),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(children: [
                        Icon(Icons.money),
                        SizedBox(width: 8),
                        Text("Tunai")
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Konten Dinamis berdasarkan Pilihan
                Expanded(
                  child: _paymentMethod == "QRIS"
                      ? _buildQrisPayment()
                      : _buildCashPayment(),
                ),

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
                        // Nonaktifkan tombol jika uang tunai kurang
                        onPressed:
                            _isLoading || !canConfirm ? null : _confirmPayment,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Konfirmasi"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
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
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildQrisPayment() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/images/qris_dana.jpg', // Pastikan path ini benar
            width: 250,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          "Scan QRIS untuk membayar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildCashPayment() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _cashController,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: "Uang Diterima",
            prefixText: "Rp ",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Kembalian:",
                style: TextStyle(fontSize: 20, color: Colors.grey)),
            Text(
              formatCurrency.format(_change),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

// lib/features/pos/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/transaction_service.dart';
import 'receipt_screen.dart';
import '../../../shared/theme.dart';
// 1. IMPOR UNTUK MENGAKSES MODEL KERANJANG
import '../models/cart_item_model.dart';

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
  // 2. UBAH STATE DEFAULT DAN TAMBAH OPSI "KARTU"
  String _paymentMethod = "Tunai"; // "Tunai", "QRIS", atau "Kartu"
  double _cashReceived = 0.0;
  double _change = 0.0;

  late double _totalPrice;
  // Daftarkan pecahan uang untuk tombol cepat
  final List<double> _cashDenominations = [20000, 50000, 100000];

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

      // Navigasi ke Struk
      if (!mounted) return;
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
      if (!mounted) return;
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
        !(_paymentMethod == "Tunai" && _cashReceived < _totalPrice) ||
            _paymentMethod == "QRIS" ||
            _paymentMethod == "Kartu";

    // 3. AMBIL DATA KERANJANG UNTUK RINGKASAN
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 4. BUNGKUS DENGAN SingleChildScrollView AGAR TIDAK OVERFLOW
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Total Pembayaran",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                Text(
                  formatCurrency.format(_totalPrice),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: primaryColor),
                ),
                const SizedBox(height: 24),

                // 5. TAMBAHKAN RINGKASAN PESANAN
                const Text(
                  "Ringkasan Pesanan:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                _buildOrderSummary(cart),
                const SizedBox(height: 24),

                // 6. PERBARUI Toggle Pilihan Pembayaran
                Center(
                  child: ToggleButtons(
                    isSelected: [
                      _paymentMethod == "Tunai",
                      _paymentMethod == "QRIS",
                      _paymentMethod == "Kartu"
                    ],
                    onPressed: (index) {
                      setState(() {
                        if (index == 0) _paymentMethod = "Tunai";
                        if (index == 1) _paymentMethod = "QRIS";
                        if (index == 2) _paymentMethod = "Kartu";
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: primaryColor,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(children: [
                          Icon(Icons.money),
                          SizedBox(width: 8),
                          Text("Tunai")
                        ]),
                      ),
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
                          Icon(Icons.credit_card),
                          SizedBox(width: 8),
                          Text("Kartu")
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 7. TAMPILKAN UI PEMBAYARAN DINAMIS
                _buildPaymentMethodDynamicUI(),

                const SizedBox(height: 80), // Beri jarak untuk tombol
              ],
            ),
          ),

          // 8. POSISIKAN TOMBOL DI BAWAH
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Row(
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

  // WIDGET BARU UNTUK RINGKASAN PESANAN
  Widget _buildOrderSummary(CartProvider cart) {
    return Container(
      height: 120, // Batasi tinggi agar tidak memakan layar
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        itemCount: cart.items.length,
        itemBuilder: (context, index) {
          final CartItem item = cart.items[index];
          return ListTile(
            dense: true,
            title: Text(item.product.name),
            leading: Text("${item.quantity}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              formatCurrency.format(item.totalPrice),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  // WIDGET BARU UNTUK KONTEN DINAMIS
  Widget _buildPaymentMethodDynamicUI() {
    switch (_paymentMethod) {
      case "Tunai":
        return _buildCashPayment();
      case "QRIS":
        return _buildQrisPayment();
      case "Kartu":
        return _buildCardPayment();
      default:
        return _buildCashPayment();
    }
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
        const SizedBox(height: 16),
        const Text(
          "Scan QRIS untuk membayar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Text(
          "(Kasir menekan konfirmasi setelah pembayaran berhasil)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // WIDGET BARU UNTUK PEMBAYARAN KARTU
  Widget _buildCardPayment() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.credit_card, size: 150, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text(
          "Silakan proses di mesin EDC",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Text(
          "(Kasir menekan konfirmasi setelah struk EDC keluar)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  // WIDGET YANG DIPERBARUI UNTUK TOMBOL CEPAT
  Widget _buildCashPayment() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
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
        const SizedBox(height: 16),
        // TOMBOL CEPAT
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: [
            // Tombol Uang Pas
            OutlinedButton(
              onPressed: () {
                _cashController.text = _totalPrice.toStringAsFixed(0);
              },
              child: const Text("Uang Pas"),
            ),
            // Tombol Pecahan
            ..._cashDenominations
                .where((value) =>
                    value >
                    _totalPrice) // Hanya tampilkan jika lebih besar dari total
                .map((value) {
              return OutlinedButton(
                onPressed: () {
                  _cashController.text = value.toStringAsFixed(0);
                },
                child: Text(formatCurrency.format(value)),
              );
            }).toList(),
          ],
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
      ],
    );
  }
}

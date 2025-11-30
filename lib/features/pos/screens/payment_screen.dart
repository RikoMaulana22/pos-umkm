import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/transaction_service.dart';
import 'receipt_screen.dart';
import '../../../shared/theme.dart';
// Import services lain (QrisService, SettingsService) jika diperlukan
import '../../settings/services/qris_service.dart';

class PaymentScreen extends StatefulWidget {
  final String storeId;
  final String subscriptionPackage;

  const PaymentScreen({
    super.key,
    required this.storeId,
    required this.subscriptionPackage,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _customerController = TextEditingController(); // Controller Nama
  
  final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final QrisService _qrisService = QrisService();
  
  String? _customQrisUrl;
  bool _isLoading = false;
  String _paymentMethod = "Tunai"; // Default
  double _cashReceived = 0.0;
  double _change = 0.0;
  double _debtAmount = 0.0; // Untuk tampilan Split

  late double _totalPrice;
  final List<double> _cashDenominations = [20000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    _totalPrice = Provider.of<CartProvider>(context, listen: false).totalPrice;
    _cashController.addListener(_calculateValues);
    _loadQrisUrl();
  }

  Future<void> _loadQrisUrl() async {
    final url = await _qrisService.loadQrisUrl();
    if (mounted) setState(() => _customQrisUrl = url);
  }

  void _calculateValues() {
    setState(() {
      _cashReceived = double.tryParse(_cashController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
      
      if (_paymentMethod == 'Split') {
        // Hitung sisa hutang
        _debtAmount = (_totalPrice > _cashReceived) ? _totalPrice - _cashReceived : 0.0;
        _change = 0.0;
      } else {
        // Hitung kembalian
        _change = (_cashReceived >= _totalPrice) ? _cashReceived - _totalPrice : 0.0;
        _debtAmount = 0.0;
      }
    });
  }

  void _confirmPayment() async {
    // Validasi input
    if ((_paymentMethod == "Hutang" || _paymentMethod == "Split") && _customerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Nama Pelanggan wajib diisi untuk transaksi ini"), backgroundColor: Colors.red));
      return;
    }
    
    if (_paymentMethod == "Tunai" && _cashReceived < _totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Uang tunai kurang"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);

    try {
      final String transactionId = await _transactionService.processTransaction(
        cart: cart,
        storeId: widget.storeId,
        paymentMethod: _paymentMethod,
        cashReceived: (_paymentMethod == 'Tunai' || _paymentMethod == 'Split') ? _cashReceived : null,
        customerName: _customerController.text.isNotEmpty ? _customerController.text : 'Umum',
      );

      if (!mounted) return;
      
      // Ke layar struk
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReceiptScreen(transactionId: transactionId)),
      );
      cart.clearCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Opsi Pembayaran yang tersedia
    final List<String> methods = ['Tunai', 'Transfer', 'QRIS', 'Hutang', 'Split'];

    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran"), backgroundColor: primaryColor, foregroundColor: Colors.white),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Display Total
                Text(formatCurrency.format(_totalPrice),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 24),
                
                // Pilihan Metode Pembayaran (Wrap Chips)
                const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: methods.map((method) {
                    final isSelected = _paymentMethod == method;
                    return ChoiceChip(
                      label: Text(method),
                      selected: isSelected,
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _paymentMethod = method;
                            _cashController.clear();
                            _calculateValues();
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Form Nama Pelanggan (Muncul jika Hutang/Split)
                if (_paymentMethod == 'Hutang' || _paymentMethod == 'Split')
                  TextField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      labelText: "Nama Pelanggan (Wajib)",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_paymentMethod == 'Hutang' || _paymentMethod == 'Split')
                  const SizedBox(height: 16),

                // UI Dinamis berdasarkan metode
                _buildDynamicContent(),
                
                const SizedBox(height: 80), // Space for button
              ],
            ),
          ),
          
          // Tombol Konfirmasi (Sama seperti sebelumnya)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Konfirmasi Pembayaran", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDynamicContent() {
    switch (_paymentMethod) {
      case 'Tunai':
      case 'Split':
        return Column(
          children: [
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Jumlah Bayar / DP",
                prefixText: "Rp ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_paymentMethod == 'Split')
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text("Sisa Hutang:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                     Text(formatCurrency.format(_debtAmount), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                   ],
                 ),
               ),
             if (_paymentMethod == 'Tunai')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Kembalian:"),
                    Text(formatCurrency.format(_change), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  ],
                )
          ],
        );
      case 'Hutang':
        return Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
           child: const Center(child: Text("Total transaksi akan dicatat sebagai hutang.")),
        );
      case 'QRIS':
        // Gunakan widget QRIS yang sudah ada
        return _customQrisUrl != null 
          ? Image.network(_customQrisUrl!, height: 200)
          : const Center(child: Text("Scan QRIS"));
      default:
        return const Center(child: Text("Selesaikan pembayaran melalui metode yang dipilih."));
    }
  }
}
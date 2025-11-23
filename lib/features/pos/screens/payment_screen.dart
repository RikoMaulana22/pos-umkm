// lib/features/pos/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/transaction_service.dart';
import 'receipt_screen.dart';
import '../../../shared/theme.dart';
import '../models/cart_item_model.dart';
import 'dart:io';
import '../../settings/services/settings_service.dart';

class PaymentScreen extends StatefulWidget {
  final String storeId;

  /// Paket langganan: 'bronze', 'silver', atau 'gold'
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
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final SettingsService _settingsService = SettingsService();

  bool _isLoading = false;
  String _paymentMethod = "Tunai";
  double _cashReceived = 0.0;
  double _change = 0.0;
  File? _qrisImage;

  late double _totalPrice;

  final List<double> _cashDenominations = [20000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    _totalPrice = Provider.of<CartProvider>(context, listen: false).totalPrice;
    _cashController.addListener(_calculateChange);
  }

  void _calculateChange() {
    setState(() {
      _cashReceived = double.tryParse(_cashController.text) ?? 0.0;
      _change =
          (_cashReceived >= _totalPrice) ? _cashReceived - _totalPrice : 0.0;
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _confirmPayment() async {
    if (_paymentMethod == "Tunai" && _cashReceived < _totalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Jumlah uang tunai tidak mencukupi"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    final cart = Provider.of<CartProvider>(context, listen: false);

    try {
      final String transactionId = await _transactionService.processTransaction(
        cart: cart,
        storeId: widget.storeId,
        paymentMethod: _paymentMethod,
        cashReceived: _paymentMethod == "Tunai" ? _cashReceived : null,
        change: _paymentMethod == "Tunai" ? _change : null,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(transactionId: transactionId),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    final bool isSilverOrGold = widget.subscriptionPackage == 'silver' ||
        widget.subscriptionPackage == 'gold';

    List<Widget> paymentButtons = [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
            children: [Icon(Icons.money), SizedBox(width: 8), Text("Tunai")]),
      ),
    ];

    List<bool> isSelected = [_paymentMethod == "Tunai"];

    if (isSilverOrGold) {
      paymentButtons.addAll([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(children: [
            Icon(Icons.qr_code),
            SizedBox(width: 8),
            Text("QRIS")
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(children: [
            Icon(Icons.credit_card),
            SizedBox(width: 8),
            Text("Kartu")
          ]),
        ),
      ]);

      isSelected.addAll([
        _paymentMethod == "QRIS",
        _paymentMethod == "Kartu",
      ]);
    }

    bool canConfirm = _paymentMethod != "Tunai" || _cashReceived >= _totalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Total Pembayaran",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: Colors.grey)),
                Text(
                  formatCurrency.format(_totalPrice),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: primaryColor),
                ),
                const SizedBox(height: 24),
                const Text("Ringkasan Pesanan:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildOrderSummary(cart),
                const SizedBox(height: 24),
                Center(
                  child: ToggleButtons(
                    isSelected: isSelected,
                    onPressed: (index) {
                      setState(() {
                        if (index == 0) _paymentMethod = "Tunai";
                        if (isSilverOrGold && index == 1)
                          _paymentMethod = "QRIS";
                        if (isSilverOrGold && index == 2)
                          _paymentMethod = "Kartu";
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: primaryColor,
                    children: paymentButtons,
                  ),
                ),
                const SizedBox(height: 24),
                _buildPaymentMethodDynamicUI(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
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
                          backgroundColor: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        itemCount: cart.items.length,
        itemBuilder: (_, i) {
          final item = cart.items[i];
          return ListTile(
            dense: true,
            title: Text(item?.product?.name ?? 'Unknown Product'),
            leading: Text("${item?.quantity ?? 0}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              formatCurrency.format(item?.totalPrice ?? 0.0),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

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
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12)),
          child: Image.asset(
            'assets/images/qris_dana.jpg',
            width: 250,
          ),
        ),
        const SizedBox(height: 16),
        const Text("Scan QRIS untuk membayar",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const Text("(Tekan konfirmasi setelah pembayaran masuk)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCardPayment() {
    return Column(
      children: [
        Icon(Icons.credit_card, size: 150, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text("Proses pembayaran melalui mesin EDC",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const Text("(Tekan konfirmasi setelah struk EDC keluar)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCashPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _cashController,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Uang Diterima",
            prefixText: "Rp ",
            border: OutlineInputBorder(),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () {
                _cashController.text = _totalPrice.toStringAsFixed(0);
              },
              child: const Text("Uang Pas"),
            ),
            ..._cashDenominations
                .where((v) => v > _totalPrice)
                .map((v) => OutlinedButton(
                      onPressed: () {
                        _cashController.text = v.toStringAsFixed(0);
                      },
                      child: Text(formatCurrency.format(v)),
                    ))
                .toList(),
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

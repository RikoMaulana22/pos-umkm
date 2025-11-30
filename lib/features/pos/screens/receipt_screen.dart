// lib/features/pos/screens/receipt_screen.dart
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../../reports/models/transaction_model.dart';
import '../../settings/services/printer_service.dart';

class ReceiptScreen extends StatefulWidget {
  final String transactionId;
  const ReceiptScreen({super.key, required this.transactionId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final PrinterService _printerService = PrinterService();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yyyy, HH:mm');
  bool _isPrinting = false;

  Future<void> _printReceipt(TransactionModel tx) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final printerData = await _printerService.getSavedPrinter();
      final String? address = printerData['address'];

      if (address == null || address.isEmpty) {
        throw Exception(
            "Printer belum diatur. Silakan atur di menu Pengaturan.");
      }

      final device = BluetoothDevice(printerData['name'], address);

      bool? isConnected = await _printer.isConnected;
      if (isConnected != true) {
        bool? connectResult = await _printer.connect(device);
        if (connectResult != true) {
          throw Exception(
              "Gagal terhubung ke printer. Pastikan printer menyala.");
        }
      }

      // --- CETAK HEADER ---
      _printer.printCustom("Pembayaran Berhasil", 2, 1);
      _printer.printCustom(formatDateTime.format(tx.timestamp.toDate()), 0, 1);

      // Tambahan: Nama Pelanggan (Jika ada)
      if (tx.customerName != null && tx.customerName!.isNotEmpty) {
        _printer.printCustom("Plg: ${tx.customerName}", 0, 1);
      }

      _printer.printNewLine();
      _printer.printCustom("--- Rincian Item ---", 1, 0);

      // --- CETAK ITEM ---
      for (var item in tx.items) {
        _printer.printLeftRight("${item.quantity}x ${item.productName}",
            formatCurrency.format(item.price * item.quantity), 0);
      }
      _printer.printCustom("----------------------", 1, 0);

      // --- CETAK TOTAL ---
      _printer.printLeftRight("TOTAL", formatCurrency.format(tx.totalPrice), 1);

      // --- LOGIKA TAMPILAN PEMBAYARAN BARU ---
      _printer.printLeftRight("Metode", tx.paymentMethod, 0);

      if (tx.paymentMethod == "Tunai" && tx.cashReceived != null) {
        // Logika Tunai Biasa
        _printer.printLeftRight(
            "Bayar", formatCurrency.format(tx.cashReceived), 0);
        _printer.printLeftRight("Kembali", formatCurrency.format(tx.change), 0);
      } else if (tx.paymentMethod == "Hutang" || tx.paymentMethod == "Split") {
        // Logika Hutang / Split
        _printer.printLeftRight(
            "Bayar", formatCurrency.format(tx.amountPaid), 0);
        _printer.printLeftRight(
            "Sisa Hutang", formatCurrency.format(tx.remainingDebt), 0);
        _printer.printLeftRight("Status", tx.paymentStatus, 0);
      }

      _printer.printNewLine();
      _printer.printCustom(
          tx.remainingDebt > 0
              ? "Mohon selesaikan pembayaran."
              : "Terima kasih!",
          1,
          1);
      _printer.printNewLine();
      _printer.paperCut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext ctxt) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Struk Pembayaran"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<TransactionModel>(
        future: FirebaseFirestore.instance
            .collection('transactions')
            .doc(widget.transactionId)
            .get()
            .then((doc) => TransactionModel.fromFirestore(doc)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Gagal memuat transaksi."));
          }

          final tx = snapshot.data!;
          final bool isDebtOrSplit =
              tx.paymentMethod == "Hutang" || tx.paymentMethod == "Split";

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: primaryColor, size: 80),
                const SizedBox(height: 16),
                const Text(
                  "Transaksi Berhasil!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  formatDateTime.format(tx.timestamp.toDate()),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                // Tampilkan Nama Pelanggan di UI
                if (tx.customerName != null && tx.customerName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("Pelanggan: ${tx.customerName}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),

                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      ...tx.items.map((item) {
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text(
                              "${item.quantity} x ${formatCurrency.format(item.price)}"),
                          trailing: Text(formatCurrency
                              .format(item.price * item.quantity)),
                        );
                      }),
                      const Divider(thickness: 1),
                      ListTile(
                        title: const Text("TOTAL",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          formatCurrency.format(tx.totalPrice),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      ListTile(
                        title: const Text("Metode Bayar"),
                        trailing: Text(tx.paymentMethod),
                      ),

                      // --- TAMPILAN DINAMIS BERDASARKAN METODE ---
                      if (!isDebtOrSplit && tx.cashReceived != null) ...[
                        ListTile(
                          title: const Text("Uang Tunai"),
                          trailing:
                              Text(formatCurrency.format(tx.cashReceived)),
                        ),
                        if (tx.change != null)
                          ListTile(
                            title: const Text("Kembalian"),
                            trailing: Text(formatCurrency.format(tx.change)),
                          ),
                      ],

                      if (isDebtOrSplit) ...[
                        ListTile(
                          title: const Text("Jumlah Dibayar"),
                          trailing: Text(formatCurrency.format(tx.amountPaid),
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ),
                        ListTile(
                          title: const Text("Sisa Hutang"),
                          trailing: Text(
                              formatCurrency.format(tx.remainingDebt),
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
                        ListTile(
                          title: const Text("Status"),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: tx.paymentStatus == 'Lunas'
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(tx.paymentStatus,
                                style: TextStyle(
                                    color: tx.paymentStatus == 'Lunas'
                                        ? Colors.green
                                        : Colors.deepOrange)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                // Tombol Cetak & Selesai (Tidak berubah)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPrinting ? null : () => _printReceipt(tx),
                        icon: _isPrinting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.print),
                        label:
                            Text(_isPrinting ? "Mencetak..." : "Cetak Struk"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                        ),
                        child: const Text("Selesai"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

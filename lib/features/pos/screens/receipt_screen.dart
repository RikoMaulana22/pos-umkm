// lib/features/pos/screens/receipt_screen.dart
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../../reports/models/transaction_model.dart';
// 1. IMPOR BARU
import '../../settings/services/printer_service.dart';



class ReceiptScreen extends StatefulWidget {
  final String transactionId;
  const ReceiptScreen({super.key, required this.transactionId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  // 2. BUAT STATE UNTUK SERVICE & FORMATTER
  final PrinterService _printerService = PrinterService();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yyyy, HH:mm');
  bool _isPrinting = false;

  // 3. FUNGSI UNTUK MENCETAK (DENGAN PERBAIKAN LOGIKA KONEKSI)
  Future<void> _printReceipt(TransactionModel tx) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      // 1. Dapatkan printer yang tersimpan
      final printerData = await _printerService.getSavedPrinter();
      final String? address = printerData['address'];

      if (address == null || address.isEmpty) {
        throw Exception(
            "Printer belum diatur. Silakan atur di menu Pengaturan.");
      }

      // 2. Buat objek device
      final device = BluetoothDevice(printerData['name'], address);

      // 3. Cek koneksi & hubungkan jika perlu
      bool? isConnected = await _printer.isConnected;
      if (isConnected != true) {
        // PERBAIKAN: Hubungkan dan periksa hasilnya
        bool? connectResult = await _printer.connect(device);
        if (connectResult != true) {
          // Jika koneksi gagal, lemparkan error
          throw Exception("Gagal terhubung ke printer. Pastikan printer menyala.");
        }
      }

      // 4. Format & Kirim data ke printer
      // Jika kita sampai di sini, printer seharusnya sudah terhubung.
      _printer.printCustom("Pembayaran Berhasil", 2, 1);
      _printer.printCustom(formatDateTime.format(tx.timestamp.toDate()), 0, 1);
      _printer.printNewLine();
      _printer.printCustom("--- Rincian Item ---", 1, 0);

      for (var item in tx.items) {
        _printer.printLeftRight("${item.quantity}x ${item.productName}",
            formatCurrency.format(item.price * item.quantity), 0);
      }
      _printer.printCustom("----------------------", 1, 0);
      _printer.printLeftRight("TOTAL", formatCurrency.format(tx.totalPrice), 1);

      if (tx.paymentMethod == "Tunai" && tx.cashReceived != null) {
        _printer.printLeftRight(
            "TUNAI", formatCurrency.format(tx.cashReceived), 0);
        _printer.printLeftRight("KEMBALI", formatCurrency.format(tx.change), 0);
      } else {
        _printer.printLeftRight("Metode", tx.paymentMethod, 0);
      }

      _printer.printNewLine();
      _printer.printCustom("Terima kasih!", 1, 1);
      _printer.printNewLine();
      _printer.paperCut(); // Potong kertas
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red));
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
            .doc(widget.transactionId) // 4. Gunakan widget.transactionId
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
          final bool isCashPayment = tx.paymentMethod == "Tunai";

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: primaryColor, size: 80),
                const SizedBox(height: 16),
                const Text(
                  "Pembayaran Berhasil!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  formatDateTime.format(tx.timestamp.toDate()),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                      }), // 5. Hapus .toList() yang tidak perlu
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
                      if (isCashPayment && tx.cashReceived != null)
                        ListTile(
                          title: const Text("Uang Tunai"),
                          trailing:
                              Text(formatCurrency.format(tx.cashReceived)),
                        ),
                      if (isCashPayment && tx.change != null)
                        ListTile(
                          title: const Text("Kembalian"),
                          trailing: Text(formatCurrency.format(tx.change)),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        // 6. PERBARUI ONPRESSED
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
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
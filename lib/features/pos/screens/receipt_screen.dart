// lib/features/pos/screens/receipt_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
// 1. IMPOR MODEL TRANSAKSI
import '../../reports/models/transaction_model.dart'; 

class ReceiptScreen extends StatelessWidget {
  final String transactionId;
  const ReceiptScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext ctxt) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
    final formatDateTime = DateFormat('dd/MM/yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Struk Pembayaran"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, 
      ),
      // 2. UBAH FUTUREBUILDER UNTUK MENGGUNAKAN MODEL
      body: FutureBuilder<TransactionModel>(
        future: FirebaseFirestore.instance
            .collection('transactions')
            .doc(transactionId)
            .get()
            .then((doc) => TransactionModel.fromFirestore(doc)), // Konversi ke model
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Gagal memuat transaksi."));
          }

          final tx = snapshot.data!; // 3. Gunakan objek model
          final bool isCashPayment = tx.paymentMethod == "Tunai";

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header Struk
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

                // Detail Item
                Expanded(
                  child: ListView(
                    children: [
                      // 4. Gunakan list 'items' dari model
                      ...tx.items.map((item) {
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text("${item.quantity} x ${formatCurrency.format(item.price)}"),
                          trailing: Text(formatCurrency.format(item.price * item.quantity)),
                        );
                      }).toList(),
                      const Divider(thickness: 1),
                      // Total
                      ListTile(
                        title: const Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          formatCurrency.format(tx.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      ListTile(
                        title: const Text("Metode Bayar"),
                        trailing: Text(tx.paymentMethod),
                      ),
                      // 5. Tampilkan Tunai & Kembalian jika metodenya Tunai
                      if (isCashPayment && tx.cashReceived != null)
                        ListTile(
                          title: const Text("Uang Tunai"),
                          trailing: Text(formatCurrency.format(tx.cashReceived)),
                        ),
                      if (isCashPayment && tx.change != null)
                        ListTile(
                          title: const Text("Kembalian"),
                          trailing: Text(formatCurrency.format(tx.change)),
                        ),
                    ],
                  ),
                ),

                // Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implementasi logika 'blue_thermal_printer'
                          print("Mencetak struk...");
                        },
                        icon: const Icon(Icons.print),
                        label: const Text("Cetak Struk"),
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
                          // Tutup halaman ini dan kembali ke PosScreen
                          Navigator.pop(context); 
                        },
                        child: const Text("Selesai"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                        ),
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
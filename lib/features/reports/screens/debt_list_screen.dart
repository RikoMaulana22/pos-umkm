import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';

class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Catatan Hutang"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Ambil data yang statusnya belum lunas sepenuhnya (unpaid/partial)
        stream: FirebaseFirestore.instance
            .collection('debts')
            .where('status', whereIn: ['unpaid', 'partial'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text("Tidak ada catatan hutang"));

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final remaining = (data['remainingAmount'] ?? 0).toDouble();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(data['customerName'] ?? 'Tanpa Nama', 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Hutang: ${formatCurrency.format(remaining)}"),
                      Text("Status: ${data['status'] == 'unpaid' ? 'Belum Dibayar' : 'Dicicil'}",
                          style: TextStyle(color: data['status'] == 'unpaid' ? Colors.red : Colors.orange)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _showPaymentDialog(context, docId, data['transactionId'], remaining),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text("Bayar", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String debtDocId, String transactionId, double currentDebt) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bayar Hutang"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Jumlah Pembayaran", prefixText: "Rp "),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0 || amount > currentDebt) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Jumlah tidak valid")));
                return;
              }
              
              Navigator.pop(context);
              await _processDebtPayment(debtDocId, transactionId, amount, currentDebt);
            },
            child: const Text("Bayar"),
          )
        ],
      ),
    );
  }

  Future<void> _processDebtPayment(String debtId, String transactionId, double amountPaid, double currentDebt) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final double newRemaining = currentDebt - amountPaid;
    final String newStatus = newRemaining <= 0 ? 'paid' : 'partial';

    // 1. Update Dokumen Debt
    batch.update(firestore.collection('debts').doc(debtId), {
      'remainingAmount': newRemaining,
      'amountPaid': FieldValue.increment(amountPaid),
      'status': newStatus,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // 2. Update Dokumen Transaksi Asli (untuk laporan)
    batch.update(firestore.collection('transactions').doc(transactionId), {
      'paid': FieldValue.increment(amountPaid),
      'debt': newRemaining,
      'paymentStatus': newStatus == 'paid' ? 'Lunas' : 'Sebagian',
    });

    await batch.commit();
  }
}
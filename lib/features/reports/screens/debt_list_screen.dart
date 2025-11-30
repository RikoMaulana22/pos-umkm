import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
// Pastikan path import ini sesuai dengan struktur folder Anda
import '../../pos/services/transaction_service.dart';

class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Format mata uang Rupiah
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Hutang Pelanggan"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Ambil SEMUA data hutang yang belum lunas
        stream: FirebaseFirestore.instance
            .collection('debts')
            .where('status', whereIn: ['unpaid', 'partial'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Tidak ada catatan hutang"));
          }

          // --- LOGIKA GROUPING ---
          Map<String, double> customerDebts = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['customerName'] ?? 'Tanpa Nama';
            final remaining = (data['remainingAmount'] ?? 0).toDouble();

            if (customerDebts.containsKey(name)) {
              customerDebts[name] = customerDebts[name]! + remaining;
            } else {
              customerDebts[name] = remaining;
            }
          }

          final groupedList = customerDebts.entries.toList();

          return ListView.builder(
            itemCount: groupedList.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final entry = groupedList[index];
              final customerName = entry.key;
              final totalDebt = entry.value;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      customerName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Total Hutang: ${formatCurrency.format(totalDebt)}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDebtDetailScreen(
                          customerName: customerName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- HALAMAN DETAIL HUTANG PER ORANG (DENGAN TOMBOL DETAIL BARANG) ---
class CustomerDebtDetailScreen extends StatelessWidget {
  final String customerName;

  const CustomerDebtDetailScreen({
    super.key,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Hutang: $customerName"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('debts')
            .where('customerName', isEqualTo: customerName)
            .where('status', whereIn: ['unpaid', 'partial'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Hutang sudah lunas semua!"));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docSnapshot = docs[index];
              final remaining = (data['remainingAmount'] ?? 0).toDouble();
              final transactionId = data['transactionId']; // Ambil ID Transaksi

              Timestamp? timestamp = data['createdAt'];
              String dateStr = timestamp != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
                  : '-';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Tanggal & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateStr,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: data['status'] == 'unpaid'
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              data['status'] == 'unpaid'
                                  ? 'Belum Dibayar'
                                  : 'Dicicil',
                              style: TextStyle(
                                color: data['status'] == 'unpaid'
                                    ? Colors.red.shade900
                                    : Colors.orange.shade900,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Info Nominal
                      Text(
                        "Sisa: ${formatCurrency.format(remaining)}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Total Awal: ${formatCurrency.format((data['originalTotal'] ?? 0))}",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      // Row Tombol Aksi
                      Row(
                        children: [
                          // Tombol Lihat Barang (BARU)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showTransactionDetail(
                                  context, transactionId),
                              icon: const Icon(Icons.receipt_long, size: 16),
                              label: const Text("Lihat Barang",
                                  style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: const BorderSide(color: primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tombol Bayar
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _showPaymentDialog(context, docSnapshot),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor),
                              child: const Text("Bayar",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- FUNGSI MENAMPILKAN DETAIL BARANG (BARU) ---
  void _showTransactionDetail(BuildContext context, String transactionId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6, // Setengah layar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detail Barang Belanjaan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  // Ambil data dari koleksi 'transactions' berdasarkan ID
                  future: FirebaseFirestore.instance
                      .collection('transactions')
                      .doc(transactionId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return const Center(
                          child: Text("Gagal memuat detail transaksi"));
                    }

                    final transData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final items = (transData['items'] as List<dynamic>?) ?? [];
                    final formatCurrency = NumberFormat.simpleCurrency(
                        locale: 'id_ID', decimalDigits: 0);

                    if (items.isEmpty) {
                      return const Center(child: Text("Tidak ada barang"));
                    }

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['productName'] ?? 'Produk'),
                          subtitle: Text(
                              "${item['quantity']} x ${formatCurrency.format(item['price'])}"),
                          trailing: Text(
                            formatCurrency
                                .format((item['quantity'] * item['price'])),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // LOGIKA PEMBAYARAN
  void _showPaymentDialog(BuildContext parentContext, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final TextEditingController amountController = TextEditingController();
    final transactionService = TransactionService();

    double remaining = (data['remainingAmount'] ?? 0).toDouble();
    double currentPaid = (data['amountPaid'] ?? 0).toDouble();
    double originalTotal = (data['originalTotal'] ?? 0).toDouble();
    String transactionId = data['transactionId'];

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bayar Hutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Sisa Hutang: Rp ${NumberFormat("#,##0", "id_ID").format(remaining)}'),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Bayar',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) return;
              String cleanValue = amountController.text.replaceAll('.', '');
              double? payAmount = double.tryParse(cleanValue);

              if (payAmount == null || payAmount <= 0) {
                ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(
                    content: Text('Masukkan jumlah yang valid')));
                return;
              }

              if (payAmount > remaining) {
                ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(
                    content: Text('Pembayaran melebihi sisa hutang!')));
                return;
              }

              try {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                      content: Text('Memproses pembayaran...'),
                      duration: Duration(seconds: 1)),
                );

                await transactionService.payDebt(
                  debtId: doc.id,
                  transactionId: transactionId,
                  amountPay: payAmount,
                  currentPaid: currentPaid,
                  totalDebt: originalTotal,
                );

                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                        content: Text('Pembayaran berhasil dicatat!'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
  }
}

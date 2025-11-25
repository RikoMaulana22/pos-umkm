import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/upgrade_request_model.dart';
import '../services/subscription_approval_service.dart';

class UpgradeRequestsScreen extends StatelessWidget {
  UpgradeRequestsScreen({super.key});

  final SubscriptionApprovalService _service = SubscriptionApprovalService();

  String formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }
  
  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permintaan Langganan")),
      body: StreamBuilder<List<UpgradeRequestModel>>(
        stream: _service.getPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Tidak ada permintaan baru", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(req.packageName.toUpperCase()),
                            backgroundColor: Colors.blue.shade100,
                            labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatDate(req.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.store, color: Colors.grey),
                          const SizedBox(width: 8),
                          // Idealnya kita fetch nama toko by ID, tapi ID saja cukup untuk admin teknis
                          Expanded(child: Text("Store ID: ${req.storeId}", style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            formatCurrency(req.price),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                       const SizedBox(height: 8),
                       Text("Metode: ${req.paymentMethod}"),
                      
                      const Divider(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _confirmAction(context, "Tolak", () {
                              _service.rejectRequest(req.id);
                            }),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Tolak"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Setujui & Aktifkan"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => _confirmAction(context, "Setujui", () {
                               _service.approveRequest(req);
                            }),
                          ),
                        ],
                      )
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

  void _confirmAction(BuildContext context, String action, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$action Permintaan?"),
        content: Text("Pastikan Anda sudah mengecek bukti transfer jika ada. Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Berhasil diproses"))
              );
            },
            child: const Text("Ya, Proses"),
          )
        ],
      ),
    );
  }
}
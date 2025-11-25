import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/upgrade_request_model.dart';
import '../services/subscription_approval_service.dart';

class UpgradeRequestsScreen extends StatelessWidget {
  UpgradeRequestsScreen({super.key});

  final SubscriptionApprovalService _service = SubscriptionApprovalService();

  String formatCurrency(int amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Permintaan Langganan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<UpgradeRequestModel>>(
        // Pastikan service ini mengarah ke collection 'upgradeRequests'
        // Query ini butuh INDEX di Firestore. Cek console log Anda untuk link pembuatannya.
        stream: _service.getPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Menangani error Index Firestore dengan pesan yang lebih jelas
            if (snapshot.error.toString().contains("failed-precondition")) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.settings,
                          size: 60, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text("Index Database Belum Dibuat",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text(
                        "Buka Debug Console di VS Code, cari link error 'https://console.firebase...', lalu klik untuk membuat index secara otomatis.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Tidak ada permintaan baru",
                      style: TextStyle(color: Colors.grey)),
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
              return _buildRequestCard(context, req);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, UpgradeRequestModel req) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Paket & Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(req.packageName.toUpperCase()),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  padding: EdgeInsets.zero,
                ),
                Text(
                  formatDate(req.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Body: Info Store & Harga
            _buildInfoRow(
                Icons.store_mall_directory_outlined, "Store ID", req.storeId),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.monetization_on_outlined, "Harga",
                formatCurrency(req.price),
                isBold: true, color: Colors.green),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.payment, "Metode", req.paymentMethod),

            // Bukti Transfer (Jika Ada)
            if (req.proofOfPaymentURL != null &&
                req.proofOfPaymentURL!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showImageDialog(context, req.proofOfPaymentURL!),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Lihat Bukti Transfer",
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],

            const Divider(height: 24),

            // Actions: Tolak / Terima
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _confirmAction(context, "Tolak", () {
                    _service.rejectRequest(req.id);
                  }),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                  child: const Text("Tolak"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Setujui & Aktifkan"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0),
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
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontSize: isBold ? 16 : 14,
                    color: color ?? Colors.black87))),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
        context: context,
        builder: (ctx) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text("Bukti Transfer"),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()));
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(Icons.broken_image,
                                size: 50, color: Colors.grey),
                            Text("Gagal memuat gambar"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ));
  }

  void _confirmAction(BuildContext context, String action, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$action Permintaan?"),
        content: Text(
            "Pastikan Anda sudah mengecek bukti transfer jika ada. Tindakan ini tidak dapat dibatalkan."),
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
                  const SnackBar(content: Text("Berhasil diproses")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == "Tolak" ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Ya, Proses"),
          )
        ],
      ),
    );
  }
}

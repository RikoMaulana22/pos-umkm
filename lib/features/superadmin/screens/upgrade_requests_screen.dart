// lib/features/superadmin/screens/upgrade_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/upgrade_request_model.dart';
import '../services/superadmin_service.dart';
// 1. IMPOR UNTUK MEMBUKA URL
import 'package:url_launcher/url_launcher.dart';

class UpgradeRequestsScreen extends StatefulWidget {
  const UpgradeRequestsScreen({super.key});

  @override
  State<UpgradeRequestsScreen> createState() => _UpgradeRequestsScreenState();
}

class _UpgradeRequestsScreenState extends State<UpgradeRequestsScreen> {
  final SuperAdminService _service = SuperAdminService();
  final formatCurrency =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final formatDateTime = DateFormat('dd/MM/yyyy, HH:mm');

  // Helper untuk mengambil nama toko (agar tidak perlu di-manage di model)
  Future<String> _fetchStoreName(String storeId) async {
    return await _service.getStoreName(storeId);
  }

  // 2. FUNGSI UNTUK MEMBUKA LINK BUKTI
  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tidak ada bukti pembayaran."),
          backgroundColor: Colors.orange));
      return;
    }
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal membuka link: $urlString"),
          backgroundColor: Colors.red));
    }
  }

  void _showApprovalDialog(UpgradeRequestModel request) {
    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Konfirmasi Persetujuan"),
              // 3. PERJELAS PESAN DIALOG
              content: Text(
                  "Sudahkah Anda memverifikasi bukti pembayaran? Menyetujui ini akan mengaktifkan paket ${request.packageName} untuk Toko ${request.storeName ?? request.storeId}."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoading = true;
                          });
                          try {
                            await _service.approveUpgradeRequest(request);
                            if (!mounted) return;
                            Navigator.pop(context); // Tutup dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Langganan berhasil diaktifkan!"),
                                  backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Gagal: ${e.toString()}"),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Setujui & Aktifkan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Upgrade'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UpgradeRequestModel>>(
        stream: _service.getUpgradeRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("Tidak ada permintaan upgrade baru."));
          }

          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gunakan FutureBuilder untuk mengambil nama toko
                      FutureBuilder<String>(
                        future: _fetchStoreName(request.storeId),
                        builder: (context, nameSnapshot) {
                          if (nameSnapshot.connectionState ==
                                  ConnectionState.waiting ||
                              !nameSnapshot.hasData) {
                            request.storeName = "Memuat nama toko...";
                            return const Text("Memuat nama toko...",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold));
                          }
                          request.storeName = nameSnapshot.data!;
                          return Text(
                            request.storeName!,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(Icons.inventory, "Paket",
                          request.packageName.toUpperCase()),
                      _buildInfoRow(Icons.price_check, "Harga",
                          formatCurrency.format(request.price)),
                      _buildInfoRow(Icons.calendar_today, "Diminta pada",
                          formatDateTime.format(request.requestedAt.toDate())),
                      const SizedBox(height: 16),

                      // 4. BUAT 2 TOMBOL BERdampingan
                      Row(
                        children: [
                          // Tombol Lihat Bukti
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _launchURL(request.proofOfPaymentURL),
                              icon: const Icon(Icons.image, size: 18),
                              label: const Text("Lihat Bukti"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tombol Setujui
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showApprovalDialog(request),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text("Setujui"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
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

  // Widget helper untuk baris info
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 12),
          Text("$label: ", style: TextStyle(color: Colors.grey[600])),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

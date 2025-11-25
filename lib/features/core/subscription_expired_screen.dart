import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import model dan service
import '../../features/superadmin/models/package_model.dart';
import '../../features/superadmin/services/package_service.dart';
// import 'services/subscription_service.dart'; // Tidak perlu service ini lagi di sini karena pindah ke PaymentUploadScreen

// ✅ IMPOR LAYAR PEMBAYARAN
import 'screens/payment_upload_screen.dart';

class SubscriptionExpiredScreen extends StatefulWidget {
  final String storeId;
  final String userRole;
  final bool isSuspended;

  const SubscriptionExpiredScreen({
    super.key,
    required this.storeId,
    required this.userRole,
    this.isSuspended = false,
  });

  @override
  State<SubscriptionExpiredScreen> createState() =>
      _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends State<SubscriptionExpiredScreen> {
  final PackageService _packageService = PackageService();
  // final SubscriptionService _subscriptionService = SubscriptionService(); // Tidak dipakai lagi

  String formatCurrency(int amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  void _onSelectPackage(PackageModel pkg) async {
    // Hanya Admin/Owner yang boleh memperpanjang
    if (widget.userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Silakan hubungi Pemilik Toko (Admin) untuk memperpanjang."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pilih ${pkg.name}?"),
        content: Text(
          "Anda akan memilih paket seharga ${formatCurrency(pkg.price)} "
          "untuk durasi ${pkg.durationDays} hari.\n\n"
          "Lanjutkan ke pembayaran?",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Lanjut")),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // ✅ NAVIGASI LANGSUNG KE PAYMENT UPLOAD SCREEN
      // Kita tidak lagi membuat request di sini, tapi di layar selanjutnya setelah bukti diupload
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentUploadScreen(
            storeId: widget.storeId,
            packageName: pkg.name, // Kirim nama paket
            price: pkg.price.toDouble(), // Kirim harga (konversi ke double)
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        widget.isSuspended ? "Toko Dinonaktifkan" : "Masa Aktif Habis";
    final String message = widget.isSuspended
        ? "Toko Anda telah dinonaktifkan oleh Admin Pusat karena pelanggaran atau permintaan penutupan. Silakan hubungi layanan pelanggan."
        : "Masa berlangganan Anda telah berakhir. Pilih paket baru di bawah ini untuk mengaktifkan kembali toko Anda.";
    final IconData icon =
        widget.isSuspended ? Icons.block : Icons.warning_amber_rounded;
    final Color iconColor = widget.isSuspended ? Colors.red : Colors.orange;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Icon(icon, size: 60, color: iconColor),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: StreamBuilder<List<PackageModel>>(
                stream: _packageService.getPackages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("Tidak ada paket tersedia saat ini."));
                  }

                  final packages =
                      snapshot.data!.where((p) => p.isActive).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final pkg = packages[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color:
                                index == 1 ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (index == 1)
                              Container(
                                color: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: const Text(
                                  "PALING LARIS",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Text(
                                    pkg.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    formatCurrency(pkg.price),
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).primaryColor),
                                  ),
                                  Text(
                                    "/ ${pkg.durationDays} Hari",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  ...pkg.features.map((feature) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.green, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(feature)),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: index == 1
                                            ? Colors.blue
                                            : Colors.grey[800],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => _onSelectPackage(pkg),
                                      child: const Text("Pilih Paket Ini",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

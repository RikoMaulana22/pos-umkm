// lib/features/admin/screens/manage_cashier_screen.dart
import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import 'add_cashier_screen.dart';
import '../../../shared/theme.dart';
// 1. IMPOR HALAMAN PEMBAYARAN
import '../../core/screens/payment_upload_screen.dart';

class ManageCashierScreen extends StatefulWidget {
  final String storeId;
  // 2. TAMBAHKAN VARIABEL PAKET
  final String subscriptionPackage;
  
  const ManageCashierScreen({
    super.key, 
    required this.storeId,
    required this.subscriptionPackage, // 3. TAMBAHKAN DI CONSTRUCTOR
  });

  @override
  State<ManageCashierScreen> createState() => _ManageCashierScreenState();
}

class _ManageCashierScreenState extends State<ManageCashierScreen> {
  final AuthService _authService = AuthService();
  // 4. TENTUKAN HARGA GOLD (sesuaikan jika perlu)
  final double _goldPackagePrice = 300000.0;

  // Fungsi untuk konfirmasi hapus (tidak berubah)
  void _confirmDelete(UserModel user) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Hapus ${user.username}?"),
        content: Text(
            "Apakah Anda yakin ingin menghapus user ini? Mereka tidak akan bisa login lagi."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Gunakan deleteCashier (yang hanya hapus doc firestore)
                await _authService.deleteCashier(user.uid); 
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Kasir berhasil dihapus"),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Gagal menghapus: ${e.toString()}"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 5. FUNGSI BARU UNTUK MENAMPILKAN DIALOG UPGRADE
  void _showUpgradeDialog(int currentCount) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Tampilan dialog sesuai gambar Anda [image_91833c.png]
        title: const Text("Batas User Tercapai"),
        content: Text(
          "Paket Silver Anda hanya mendukung 4 user kasir (Anda memiliki $currentCount). "
          "Silakan upgrade ke paket Gold untuk menambah kasir tanpa batas.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              
              // 6. ARAHKAN KE HALAMAN PEMBAYARAN
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentUploadScreen(
                    storeId: widget.storeId,
                    packageName: 'gold', // Target paket
                    price: _goldPackagePrice, // Harga paket Gold
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
            child: const Text("Upgrade ke Gold"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 7. BUNGKUS SELURUH SCAFFOLD DENGAN STREAMBUILDER
    return StreamBuilder<List<UserModel>>(
      stream: _authService.getCashiers(widget.storeId),
      builder: (context, snapshot) {
        
        // Tentukan state data
        final bool hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final cashierList = hasData ? snapshot.data! : <UserModel>[];
        
        // 8. TENTUKAN LOGIKA BATAS DI SINI
        final int kasirCount = cashierList.length;
        final bool isGold = widget.subscriptionPackage == 'gold';
        // Batas adalah 4
        final bool limitReached = kasirCount >= 4; 

        return Scaffold(
          appBar: AppBar(
            title: const Text("Manajemen Kasir"),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error.toString()}"));
              }
              if (!hasData) {
                return const Center(child: Text("Belum ada kasir."));
              }

              // Data ada, build ListView
              return ListView.builder(
                itemCount: cashierList.length,
                itemBuilder: (context, index) {
                  final user = cashierList[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.point_of_sale, size: 20),
                      ),
                      title: Text(user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(user),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // 9. GUNAKAN VARIABEL YANG SUDAH SIAP
              if (!isGold && limitReached) {
                // Jika BUKAN Gold dan limit tercapai
                _showUpgradeDialog(kasirCount);
              } else {
                // Jika Gold ATAU (Silver dan limit belum tercapai)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddCashierScreen(storeId: widget.storeId),
                  ),
                );
              }
            },
            backgroundColor: (!isGold && limitReached) ? Colors.grey : primaryColor, // Ubah warna jika disabled
            foregroundColor: Colors.white,
            // 10. Tampilkan gembok jika limit tercapai
            child: Icon(!isGold && limitReached ? Icons.lock : Icons.add),
            tooltip: "Tambah Kasir Baru",
          ),
        );
      },
    );
  }
}
// lib/features/admin/screens/manage_cashier_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import 'add_cashier_screen.dart';

class ManageCashierScreen extends StatefulWidget {
  final String storeId;
  const ManageCashierScreen({super.key, required this.storeId});

  @override
  State<ManageCashierScreen> createState() => _ManageCashierScreenState();
}

class _ManageCashierScreenState extends State<ManageCashierScreen> {
  final AuthService _authService = AuthService();

  void _showDeleteDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Kasir"),
          content: Text("Anda yakin ingin menghapus akun kasir '${user.username}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _authService.deleteCashier(user.uid);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Kasir berhasil dihapus"),
                      backgroundColor: Colors.green));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Gagal menghapus: ${e.toString()}"),
                      backgroundColor: Colors.red));
                }
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kasir'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Tambah Kasir Baru",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCashierScreen(storeId: widget.storeId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _authService.getCashiers(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada akun kasir.\nTekan tombol + untuk menambah.",
                textAlign: TextAlign.center,
              ),
            );
          }

          final cashiers = snapshot.data!;
          return ListView.builder(
            itemCount: cashiers.length,
            itemBuilder: (context, index) {
              final user = cashiers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    foregroundColor: primaryColor,
                    child: const Icon(Icons.person),
                  ),
                  title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteDialog(user),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
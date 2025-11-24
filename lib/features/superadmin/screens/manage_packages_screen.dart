// lib/features/superadmin/screens/manage_packages_screen.dart
import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../services/superadmin_service.dart';

class ManagePackagesScreen extends StatefulWidget {
  const ManagePackagesScreen({super.key});

  @override
  State<ManagePackagesScreen> createState() => _ManagePackagesScreenState();
}

class _ManagePackagesScreenState extends State<ManagePackagesScreen> {
  final SuperAdminService _service = SuperAdminService();

  // Fungsi Menampilkan Dialog Edit
  void _showEditDialog(
      BuildContext context, List<PackageModel> allPackages, int index) {
    final package = allPackages[index];
    final priceController =
        TextEditingController(text: package.price.toStringAsFixed(0));

    // Variabel lokal dialog untuk status loading
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Dialog tidak bisa ditutup saat loading
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Edit Harga ${package.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  enabled: !isSaving, // Disable input saat menyimpan
                  decoration: const InputDecoration(
                    labelText: 'Harga Paket (Rp)',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: 150000',
                  ),
                ),
                if (isSaving) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text("Menyimpan perubahan..."),
                ]
              ],
            ),
            actions: [
              if (!isSaving)
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
              if (!isSaving) // Sembunyikan tombol saat loading
                ElevatedButton(
                  onPressed: () async {
                    // 1. Validasi Input
                    if (priceController.text.isEmpty) return;

                    final newPrice = double.tryParse(priceController.text
                        .replaceAll('.',
                            '')); // Hapus titik jika user pakai format ribuan

                    if (newPrice == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Masukkan angka yang valid!')));
                      return;
                    }

                    // 2. Tampilkan Loading (Update UI Dialog)
                    setStateDialog(() {
                      isSaving = true;
                    });

                    try {
                      // 3. Update Data di List Lokal
                      // Kita buat object baru untuk item yang diedit
                      final updatedPackage = PackageModel(
                        id: package.id,
                        name: package.name,
                        price: newPrice,
                        features: package.features,
                      );

                      // Update list
                      allPackages[index] = updatedPackage;

                      // 4. Kirim ke Firebase Service
                      await _service.updatePackage(allPackages);

                      // 5. Jika Berhasil
                      if (context.mounted) {
                        Navigator.pop(context); // Tutup Dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Harga Berhasil Disimpan!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // 6. Jika Gagal (Error)
                      // Print error ke console untuk debugging
                      print("ERROR SAVE: $e");

                      if (context.mounted) {
                        setStateDialog(() {
                          isSaving = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Gagal menyimpan: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Harga Paket'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<List<PackageModel>>(
        stream: _service.getPackages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
            ));
          }

          var packages = snapshot.data ?? [];

          // Jika data kosong, inisialisasi default
          if (packages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum ada data paket di database."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      // Buat data default
                      final defaults = [
                        PackageModel(
                            id: 'bronze',
                            name: 'Bronze',
                            price: 50000,
                            features: ['Basic Features']),
                        PackageModel(
                            id: 'silver',
                            name: 'Silver',
                            price: 100000,
                            features: ['Advanced Features']),
                        PackageModel(
                            id: 'gold',
                            name: 'Gold',
                            price: 150000,
                            features: ['All Features']),
                      ];
                      await _service.updatePackage(defaults);
                    },
                    child: const Text("Buat Paket Default"),
                  )
                ],
              ),
            );
          }

          // Urutkan paket: Bronze -> Silver -> Gold
          packages.sort((a, b) {
            final order = {'bronze': 1, 'silver': 2, 'gold': 3};
            return (order[a.id] ?? 99).compareTo(order[b.id] ?? 99);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: packages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pkg = packages[index];

              // Tentukan warna icon berdasarkan paket
              Color iconColor;
              switch (pkg.id.toLowerCase()) {
                case 'gold':
                  iconColor = Colors.amber;
                  break;
                case 'silver':
                  iconColor = Colors.grey;
                  break;
                default:
                  iconColor = Colors.brown;
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(Icons.star, color: iconColor),
                  ),
                  title: Text(pkg.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Rp ${pkg.price.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: Colors.green[700], fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(context, packages, index),
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

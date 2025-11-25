import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/package_model.dart';
import '../services/package_service.dart';

class ManagePackagesScreen extends StatefulWidget {
  const ManagePackagesScreen({super.key});

  @override
  State<ManagePackagesScreen> createState() => _ManagePackagesScreenState();
}

class _ManagePackagesScreenState extends State<ManagePackagesScreen> {
  final PackageService _packageService = PackageService();

  // Helper format currency
  String formatCurrency(int amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Paket Langganan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_page_outlined),
            tooltip: "Generate Default Packages",
            onPressed: () async {
              // Tombol darurat untuk isi data jika kosong
              await _packageService.initializeDefaultPackages();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Cek & inisialisasi paket selesai")),
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<List<PackageModel>>(
        // PERBAIKAN: getPackagesStream -> getPackages
        stream: _packageService.getPackages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                  "Belum ada paket. Tekan tombol refresh di pojok kanan atas."),
            );
          }

          final packages = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final pkg = packages[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            pkg.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Switch(
                            value: pkg.isActive,
                            onChanged: (val) {
                              _packageService
                                  .updatePackage(pkg.id, {'isActive': val});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // PERBAIKAN: durationInDays -> durationDays
                        "${formatCurrency(pkg.price)} / ${pkg.durationDays} Hari",
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const Text("Fitur:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...pkg.features.map((f) => Row(
                            children: [
                              const Icon(Icons.check,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f)),
                            ],
                          )),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit Paket"),
                          onPressed: () => _showEditDialog(context, pkg),
                        ),
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

  void _showEditDialog(BuildContext context, PackageModel pkg) {
    final nameController = TextEditingController(text: pkg.name);
    final priceController = TextEditingController(text: pkg.price.toString());
    // PERBAIKAN: durationInDays -> durationDays
    final durationController =
        TextEditingController(text: pkg.durationDays.toString());

    // Gabungkan fitur jadi satu string dipisah koma
    final featuresController =
        TextEditingController(text: pkg.features.join(', '));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit ${pkg.name}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nama Paket"),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Harga (Rp)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: "Durasi (Hari)"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                const Text("Fitur (Pisahkan dengan koma):",
                    style: TextStyle(fontSize: 12)),
                TextField(
                  controller: featuresController,
                  decoration: const InputDecoration(
                    hintText: "Contoh: Laporan PDF, Backup, 3 Kasir",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                List<String> featureList = featuresController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                _packageService.updatePackage(pkg.id, {
                  'name': nameController.text,
                  'price': int.tryParse(priceController.text) ?? 0,
                  // PERBAIKAN: durationInDays -> durationDays (Database Key)
                  'durationDays': int.tryParse(durationController.text) ?? 30,
                  'features': featureList,
                });
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }
}

// lib/features/core/screens/subscription_package_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
import '../../superadmin/models/package_model.dart'; // Pastikan file ini ada
import '../../superadmin/services/superadmin_service.dart'; // Pastikan file ini ada
import 'payment_upload_screen.dart';

class SubscriptionPackageScreen extends StatefulWidget {
  final String storeId;
  const SubscriptionPackageScreen({super.key, required this.storeId});

  @override
  State<SubscriptionPackageScreen> createState() =>
      _SubscriptionPackageScreenState();
}

class _SubscriptionPackageScreenState extends State<SubscriptionPackageScreen> {
  String _selectedPackage = '';

  @override
  Widget build(BuildContext context) {
    // 🎨 Metadata statis untuk tampilan (Emoji & Deskripsi)
    // Harga & Fitur akan ditimpa oleh data dari Database Admin
    final Map<String, Map<String, dynamic>> packageMetadata = {
      'bronze': {
        'emoji': '🟫',
        'desc': 'Untuk Pemula',
        'isPopular': false,
        'defaultPrice': 129000.0,
        'defaultFeatures': [
          "Input Produk Basic",
          "Penjualan Basic",
          "Struk Digital"
        ]
      },
      'silver': {
        'emoji': '⚪',
        'desc': 'Untuk Berkembang',
        'isPopular': true,
        'defaultPrice': 249000.0,
        'defaultFeatures': [
          "Semua fitur Bronze",
          "Multi Payment",
          "Laporan Bulanan"
        ]
      },
      'gold': {
        'emoji': '🟨',
        'desc': 'Untuk Enterprise',
        'isPopular': false,
        'defaultPrice': 359000.0,
        'defaultFeatures': ["Semua fitur Silver", "Multi Outlet", "Support VIP"]
      },
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('💳 Pilih Paket Langganan'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // ✅ STREAMBUILDER: Mengambil data paket real-time dari Firebase Admin
      body: StreamBuilder<List<PackageModel>>(
        stream: SuperAdminService().getPackages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error memuat paket: ${snapshot.error}"));
          }

          List<PackageModel> packages = snapshot.data ?? [];

          // JIKA DB KOSONG (Admin belum setup): Gunakan data default dari metadata
          if (packages.isEmpty) {
            packages = packageMetadata.entries.map((entry) {
              return PackageModel(
                id: entry.key,
                name: entry.key[0].toUpperCase() + entry.key.substring(1),
                price: (entry.value['defaultPrice'] as num).toDouble(),
                // 🔥 PERBAIKAN: Cast List<dynamic> ke List<String> dengan aman
                features:
                    List<String>.from(entry.value['defaultFeatures'] ?? []),
              );
            }).toList();
          }

          // Urutkan paket: Bronze -> Silver -> Gold (berdasarkan ID)
          packages.sort((a, b) {
            final order = {'bronze': 1, 'silver': 2, 'gold': 3};
            // Paket selain 3 di atas akan ditaruh di paling bawah
            final indexA = order[a.id.toLowerCase()] ?? 99;
            final indexB = order[b.id.toLowerCase()] ?? 99;
            return indexA.compareTo(indexB);
          });

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: packages.map((pkg) {
                      // Ambil metadata tampilan (Emoji, desc) berdasarkan ID paket
                      // Jika paket baru (custom), gunakan default emoji paket
                      final meta = packageMetadata[pkg.id.toLowerCase()] ??
                          {
                            'emoji': '📦',
                            'desc': 'Paket Spesial',
                            'isPopular': false
                          };

                      return Column(
                        children: [
                          _buildPackageCard(
                            context: context,
                            title: pkg.name, // Nama dari Database
                            emoji: meta['emoji'],
                            description: meta['desc'],
                            price: pkg.price, // Harga dari Database
                            features: pkg.features, // Fitur dari Database
                            packageName: pkg.id,
                            isPopular: meta['isPopular'],
                            isSelected: _selectedPackage == pkg.id,
                            onSelect: () => _selectPackage(pkg.id, pkg.price),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectPackage(String packageName, double price) {
    setState(() {
      _selectedPackage = packageName;
    });
    _showConfirmationDialog(packageName, price);
  }

  void _showConfirmationDialog(String packageName, double price) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 60, color: Colors.green[600]),
                const SizedBox(height: 16),
                Text(
                  'Paket ${packageName.toUpperCase()} Dipilih',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Harga: ${formatCurrency.format(price)}/bulan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Kirim harga yang dipilih (dari database) ke Payment Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentUploadScreen(
                                storeId: widget.storeId,
                                packageName: packageName,
                                price: price,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Lanjut',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
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
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Paket Berlangganan',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih paket yang sesuai dengan kebutuhan bisnis Anda',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required BuildContext context,
    required String title,
    required String emoji,
    required String description,
    required double price,
    required List<String> features,
    required String packageName,
    required bool isPopular,
    required VoidCallback onSelect,
    required bool isSelected,
  }) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPopular ? primaryColor : Colors.grey[200]!,
          width: isPopular ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? primaryColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: isPopular ? 20 : 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:
                  isPopular ? primaryColor.withOpacity(0.05) : Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$emoji Paket $title',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(description,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                if (isPopular)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('POPULER',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatCurrency.format(price),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
                const SizedBox(height: 12),
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(f,
                                  style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? primaryColor : Colors.grey[200],
                      foregroundColor:
                          isSelected ? Colors.white : Colors.black87,
                    ),
                    child: Text(isSelected ? 'Dipilih' : 'Pilih Paket'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

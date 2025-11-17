// lib/features/core/screens/subscription_package_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart';
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
    final prices = {
      'bronze': 50000.0,
      'silver': 150000.0,
      'gold': 300000.0,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('💳 Pilih Paket Langganan'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ✨ Header Section
            _buildHeaderSection(),

            const SizedBox(height: 30),

            // ✨ Package Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildPackageCard(
                    context: context,
                    title: "Bronze",
                    emoji: "🟫",
                    description: "Untuk Pemula",
                    price: prices['bronze']!,
                    features: [
                      "Input Produk Basic",
                      "Penjualan Basic (Cash Only)",
                      "Struk via Printer Bluetooth",
                      "Manajemen Stok Sederhana",
                      "Dashboard Laporan Harian",
                      "1 User Login / 1 Outlet",
                      "Support Chat Basic"
                    ],
                    packageName: 'bronze',
                    isPopular: false,
                    onSelect: () => _selectPackage('bronze', prices['bronze']!),
                    isSelected: _selectedPackage == 'bronze',
                  ),
                  const SizedBox(height: 16),
                  _buildPackageCard(
                    context: context,
                    title: "Silver",
                    emoji: "⚪",
                    description: "Untuk Berkembang",
                    price: prices['silver']!,
                    features: [
                      "Semua fitur Bronze",
                      "Multi Payment (Cash, eWallet, Transfer)",
                      "Diskon, Promo, & Voucher",
                      "Multi User (3-5 user)",
                      "Export Laporan (PDF/Excel)",
                      "Laporan Mingguan & Bulanan",
                      "Support Prioritas"
                    ],
                    packageName: 'silver',
                    isPopular: true,
                    onSelect: () => _selectPackage('silver', prices['silver']!),
                    isSelected: _selectedPackage == 'silver',
                  ),
                  const SizedBox(height: 16),
                  _buildPackageCard(
                    context: context,
                    title: "Gold",
                    emoji: "🟨",
                    description: "Untuk Enterprise",
                    price: prices['gold']!,
                    features: [
                      "Semua fitur Silver",
                      "Multi Outlet (Cabang)",
                      "Manajemen Akses User Lengkap",
                      "Manajemen Stok Advance",
                      "Cloud Backup Harian",
                      "Advanced Analytics",
                      "Support VIP 24/7"
                    ],
                    packageName: 'gold',
                    isPopular: false,
                    onSelect: () => _selectPackage('gold', prices['gold']!),
                    isSelected: _selectedPackage == 'gold',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _selectPackage(String packageName, double price) {
    setState(() {
      _selectedPackage = packageName;
    });

    // Show confirmation dialog
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
                Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: Colors.green[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Paket ${packageName.toUpperCase()} Dipilih',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Harga: ${formatCurrency.format(price)}/bulan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anda akan diarahkan ke halaman pembayaran',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Lanjut ke Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
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
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih paket yang sesuai dengan kebutuhan bisnis Anda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
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
            offset: isPopular ? const Offset(0, 8) : const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✨ Package Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: isPopular
                  ? LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        Colors.blue.withOpacity(0.05)
                      ],
                    )
                  : LinearGradient(
                      colors: [Colors.grey[100]!, Colors.grey[50]!],
                    ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$emoji Paket $title',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'POPULER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ✨ Price Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga per bulan',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatCurrency.format(price),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // ✨ Features List
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ✨ CTA Button
          Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? primaryColor : Colors.grey[200],
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: isSelected ? 2 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.arrow_forward,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSelected ? 'Dipilih' : 'Pilih Paket',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

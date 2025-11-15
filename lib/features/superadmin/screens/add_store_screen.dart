// lib/features/superadmin/screens/add_store_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/superadmin_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';

class AddStoreScreen extends StatefulWidget {
  const AddStoreScreen({super.key});

  @override
  State<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final SuperAdminService _service = SuperAdminService();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController adminUsernameController = TextEditingController();
  final TextEditingController adminEmailController = TextEditingController();
  final TextEditingController adminPasswordController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  DateTime? _selectedExpiryDate;
  bool _isLoading = false;
  String _selectedPackage = 'bronze'; // <-- 1. TAMBAH STATE PAKET

  // 2. ATUR DEFAULT TRIAL 30 HARI DI initState
  @override
  void initState() {
    super.initState();
    // Atur tanggal kedaluwarsa default ke 30 hari dari sekarang
    _selectedExpiryDate = DateTime.now().add(const Duration(days: 30));
    expiryDateController.text =
        DateFormat('dd/MM/yyyy').format(_selectedExpiryDate!);
    // Atur harga default (misal 0 untuk trial)
    priceController.text = "0";
  }

  // Fungsi untuk menampilkan pemilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ??
          DateTime.now().add(const Duration(days: 30)), // Gunakan state
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
        expiryDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _saveStore() async {
    // Validasi
    if (storeNameController.text.isEmpty ||
        adminUsernameController.text.isEmpty ||
        adminEmailController.text.isEmpty ||
        adminPasswordController.text.isEmpty ||
        priceController.text.isEmpty ||
        _selectedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Semua field harus diisi"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _service.createStoreWithAdmin(
        adminEmail: adminEmailController.text,
        adminPassword: adminPasswordController.text,
        adminUsername: adminUsernameController.text,
        storeName: storeNameController.text,
        expiryDate: _selectedExpiryDate!,
        subscriptionPrice: double.parse(priceController.text),
        subscriptionPackage: _selectedPackage, // <-- 3. KIRIM PAKET
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Toko dan Admin baru berhasil dibuat!"),
          backgroundColor: Colors.green));

      // Admin tidak akan logout karena service sudah diperbaiki
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal: ${e.toString()}"),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Toko Baru'),
        backgroundColor: Colors.red[800], // Warna Super Admin
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Detail Toko",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: storeNameController, hintText: "Nama Toko"),

                const SizedBox(height: 24),
                const Text("Akun Admin (Owner)",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: adminUsernameController,
                    hintText: "Username Admin"),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: adminEmailController,
                    hintText: "Email Admin",
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: adminPasswordController,
                    hintText: "Password Admin",
                    obscureText: true),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: priceController,
                    hintText: "Harga Sewa (Rp)",
                    keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                const Text("Langganan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // 4. TAMBAHKAN DROPDOWN PAKET
                DropdownButtonFormField<String>(
                  value: _selectedPackage,
                  decoration: const InputDecoration(
                    labelText: "Paket Langganan Awal",
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'bronze', child: Text("🟫 Bronze (Dasar)")),
                    DropdownMenuItem(
                        value: 'silver', child: Text("⚪ Silver (Berkembang)")),
                    DropdownMenuItem(
                        value: 'gold', child: Text("🟨 Gold (Skala Besar)")),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPackage = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Field Tanggal Kedaluwarsa
                TextField(
                  controller: expiryDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Tanggal Kedaluwarsa (Trial 30 Hari)",
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  onTap: () => _selectDate(context),
                ),

                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _saveStore,
                  text: "Simpan Toko & Admin",
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
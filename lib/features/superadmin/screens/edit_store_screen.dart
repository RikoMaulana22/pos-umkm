// lib/features/superadmin/screens/edit_store_screen.dart
import 'package:erp_umkm/shared/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/superadmin_service.dart';
import '../../settings/models/store_model.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Timestamp

class EditStoreScreen extends StatefulWidget {
  final StoreModel store;
  const EditStoreScreen({super.key, required this.store});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final SuperAdminService _service = SuperAdminService();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();

  DateTime? _selectedExpiryDate;
  bool _isLoading = false;
  bool _isActive = true;
  String _selectedPackage = 'bronze'; // <-- 1. TAMBAH STATE PAKET

  @override
  void initState() {
    super.initState();
    storeNameController.text = widget.store.name;

    FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.store.id)
        .get()
        .then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final double price = (data['subscriptionPrice'] ?? 0.0).toDouble();
        final Timestamp? expiry = data['subscriptionExpiry'];

        setState(() {
          priceController.text = price.toStringAsFixed(0);
          _isActive = data['isActive'] ?? true;
          _selectedPackage =
              data['subscriptionPackage'] ?? 'bronze'; // <-- 2. AMBIL PAKET
          if (expiry != null) {
            _selectedExpiryDate = expiry.toDate();
            expiryDateController.text =
                DateFormat('dd/MM/yyyy').format(_selectedExpiryDate!);
          }
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
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

  void _updateStore() async {
    if (storeNameController.text.isEmpty ||
        priceController.text.isEmpty ||
        _selectedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Nama, Harga, dan Tanggal harus diisi"),
          backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await _service.updateStoreSubscription(
        storeId: widget.store.id,
        newName: storeNameController.text,
        newExpiryDate: _selectedExpiryDate!,
        newPrice: double.parse(priceController.text),
        isActive: _isActive,
        newPackage: _selectedPackage, // <-- 3. KIRIM PAKET BARU
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Data toko berhasil diperbarui!"),
          backgroundColor: Colors.green));
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

  void _deleteStore() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Toko Ini?"),
        content: Text(
            "PERINGATAN: Menghapus toko '${widget.store.name}' akan menghapus data admin dan tokonya. Lanjutkan?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == null || !confirm) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await _service.deleteStore(widget.store.id, widget.store.ownerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Toko berhasil dihapus."),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal menghapus: ${e.toString()}"),
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
        title: Text('Edit Toko: ${widget.store.name}'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _deleteStore,
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Toko",
          )
        ],
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
                  controller: storeNameController,
                  hintText: "Nama Toko",
                ),
                const SizedBox(height: 24),
                const Text("Pengaturan Langganan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: priceController,
                    hintText: "Harga Sewa (Rp)",
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),

                // 4. TAMBAHKAN DROPDOWN PAKET
                DropdownButtonFormField<String>(
                  value: _selectedPackage,
                  decoration: const InputDecoration(
                    labelText: "Paket Langganan",
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

                TextField(
                  controller: expiryDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: "Pilih Tanggal Kedaluwarsa Baru",
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text("Toko Aktif"),
                    subtitle: Text(_isActive
                        ? "Toko dapat beroperasi"
                        : "Toko dinonaktifkan (suspended)"),
                    value: _isActive,
                    onChanged: (bool value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    activeColor: primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  onTap: _isLoading ? null : _updateStore,
                  text: "Update Data Toko",
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

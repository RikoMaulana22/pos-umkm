// lib/features/superadmin/screens/add_store_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
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
  final TextEditingController locationController =
      TextEditingController(); // Field lokasi
  final TextEditingController adminUsernameController = TextEditingController();
  final TextEditingController adminEmailController = TextEditingController();
  final TextEditingController adminPasswordController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  DateTime? _selectedExpiryDate;
  bool _isLoading = false;
  bool _showPassword = false;
  String _selectedPackage = 'bronze';
  Position? _currentPosition;

  final Color superAdminColor = Colors.red[800]!;

  @override
  void initState() {
    super.initState();
    _selectedExpiryDate = DateTime.now().add(const Duration(days: 30));
    expiryDateController.text =
        DateFormat('dd/MM/yyyy').format(_selectedExpiryDate!);
    priceController.text = "0";
  }

  @override
  void dispose() {
    storeNameController.dispose();
    locationController.dispose();
    adminUsernameController.dispose();
    adminEmailController.dispose();
    adminPasswordController.dispose();
    expiryDateController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: superAdminColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
        expiryDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Cek layanan lokasi
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar("Location services are disabled.");
      return;
    }
    // Cek permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar("Location permissions are denied.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar("Location permissions are permanently denied.");
      return;
    }

    // Ambil posisi perangkat
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
      locationController.text = "${position.latitude}, ${position.longitude}";
    });
  }

  void _saveStore() async {
    if (storeNameController.text.isEmpty ||
        locationController.text.isEmpty ||
        adminUsernameController.text.isEmpty ||
        adminEmailController.text.isEmpty ||
        adminPasswordController.text.isEmpty ||
        priceController.text.isEmpty ||
        _selectedExpiryDate == null) {
      _showErrorSnackBar("Semua field harus diisi");
      return;
    }

    // Validate email format
    if (!_isValidEmail(adminEmailController.text)) {
      _showErrorSnackBar("Format email tidak valid");
      return;
    }

    // Validate password length
    if (adminPasswordController.text.length < 6) {
      _showErrorSnackBar("Password minimal 6 karakter");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.createStoreWithAdmin(
        adminEmail: adminEmailController.text,
        adminPassword: adminPasswordController.text,
        adminUsername: adminUsernameController.text,
        storeName: storeNameController.text,
        location: locationController.text,
        expiryDate: _selectedExpiryDate!,
        subscriptionPrice: double.parse(priceController.text),
        subscriptionPackage: _selectedPackage,
      );
      if (!mounted) return;
      _showSuccessSnackBar("Toko dan Admin berhasil dibuat!");
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar("Gagal: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🏪 Tambah Toko Baru'),
        backgroundColor: superAdminColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✨ Header Card
                _buildHeaderCard(),

                const SizedBox(height: 32),

                // ✨ Store Details Section
                _buildSectionHeader("🏪 Detail Toko"),
                const SizedBox(height: 16),
                _buildStoreSection(),

                const SizedBox(height: 32),

                // ✨ Admin Account Section
                _buildSectionHeader("👤 Akun Admin (Owner)"),
                const SizedBox(height: 16),
                _buildAdminSection(),

                const SizedBox(height: 32),

                // ✨ Subscription Section
                _buildSectionHeader("💳 Langganan"),
                const SizedBox(height: 16),
                _buildSubscriptionSection(),

                const SizedBox(height: 40),

                // ✨ Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: superAdminColor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _isLoading ? "Membuat Toko..." : "✅ Simpan Toko & Admin",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // ✨ Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: superAdminColor),
                      const SizedBox(height: 20),
                      const Text(
                        "Membuat toko baru...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
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

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            superAdminColor.withOpacity(0.1),
            Colors.red.withOpacity(0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: superAdminColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: superAdminColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_business_rounded,
              color: superAdminColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tambah Toko Baru",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Buat toko baru dengan admin owner",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: superAdminColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: storeNameController,
            hintText: "Nama Toko (contoh: Toko Makmur)",
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: locationController,
            hintText: "Lokasi Toko (otomatis atau manual)",
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
                icon: const Icon(Icons.my_location),
                label: const Text("Ambil Lokasi Otomatis"),
              ),
              const SizedBox(width: 16),
              if (_currentPosition != null)
                Text(
                  "Lokasi didapat ✔️",
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: adminUsernameController,
            hintText: "Username Admin",
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: adminEmailController,
            hintText: "Email Admin (contoh: admin@toko.com)",
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: adminPasswordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              hintText: "Password Admin (minimal 6 karakter)",
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: superAdminColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Dropdown
          Text(
            "Paket Langganan",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPackage,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.card_membership_rounded, color: superAdminColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: superAdminColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'bronze',
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.brown),
                    SizedBox(width: 8),
                    Text("Bronze (Dasar)"),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'silver',
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.grey),
                    SizedBox(width: 8),
                    Text("Silver (Berkembang)"),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'gold',
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber),
                    SizedBox(width: 8),
                    Text("Gold (Skala Besar)"),
                  ],
                ),
              ),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedPackage = newValue);
              }
            },
          ),
          const SizedBox(height: 16),

          // Price Field
          Text(
            "Harga Sewa",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "0",
              prefixIcon:
                  Icon(Icons.attach_money_rounded, color: superAdminColor),
              prefixText: "Rp ",
              prefixStyle: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: superAdminColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Expiry Date Field
          Text(
            "Tanggal Kedaluwarsa",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: expiryDateController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Pilih tanggal",
              prefixIcon:
                  Icon(Icons.calendar_today_rounded, color: superAdminColor),
              suffixIcon:
                  Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: superAdminColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 12),

          // Info Note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.blue[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Default trial: 30 hari dari sekarang",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
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

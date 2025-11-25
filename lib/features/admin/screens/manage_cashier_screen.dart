// lib/features/admin/screens/manage_cashier_screen.dart
import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import 'add_cashier_screen.dart';
import '../../../shared/theme.dart';
import '../../core/screens/payment_upload_screen.dart';

class ManageCashierScreen extends StatefulWidget {
  final String storeId;
  final String subscriptionPackage;

  const ManageCashierScreen({
    super.key,
    required this.storeId,
    required this.subscriptionPackage,
  });

  @override
  State<ManageCashierScreen> createState() => _ManageCashierScreenState();
}

class _ManageCashierScreenState extends State<ManageCashierScreen> {
  final AuthService _authService = AuthService();
  final double _goldPackagePrice = 300000.0;

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red[400], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text("Hapus ${user.username}?"),
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus kasir ini? Mereka tidak akan bisa login lagi ke aplikasi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.deleteCashier(user.uid);
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar("Kasir berhasil dihapus");
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar("Gagal menghapus: ${e.toString()}");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Hapus",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(int currentCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber[700], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: const Text("Upgrade ke Gold"),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded, color: Colors.amber[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Batas User Tercapai",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Paket Silver: Maksimal 4 kasir",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Upgrade ke Paket Gold untuk menambah kasir tanpa batas dan fitur premium lainnya.",
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Harga Paket Gold:",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "Rp ${(_goldPackagePrice / 1000).toStringAsFixed(0)}K",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nanti Saja"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentUploadScreen(
                    storeId: widget.storeId,
                    packageName: 'gold',
                    price: _goldPackagePrice,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              "Upgrade Sekarang",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
    return StreamBuilder<List<UserModel>>(
      stream: _authService.getCashiers(widget.storeId),
      builder: (context, snapshot) {
        final bool hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final cashierList = hasData ? snapshot.data! : <UserModel>[];

        final int kasirCount = cashierList.length;
        final bool isGold = widget.subscriptionPackage == 'gold';
        final bool limitReached = kasirCount >= 4;
        final bool canAddMore = isGold || !limitReached;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('👥 Manajemen Kasir'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat data kasir...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 80, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Terjadi Kesalahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (!hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 100, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Kasir',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan kasir baru untuk mulai',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✨ Info Card
                    _buildInfoCard(kasirCount, isGold, limitReached),

                    const SizedBox(height: 24),

                    // ✨ Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Daftar Kasir (${cashierList.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (!isGold && limitReached)
                          Tooltip(
                            message: 'Batas Silver: 4 kasir',
                            child: Icon(
                              Icons.info_rounded,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ✨ Cashier List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cashierList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = cashierList[index];
                        return _buildCashierCard(user);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: _buildFAB(canAddMore, kasirCount),
        );
      },
    );
  }

  Widget _buildInfoCard(int kasirCount, bool isGold, bool limitReached) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGold
              ? [Colors.amber[400]!, Colors.amber[600]!]
              : [Colors.blue[400]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isGold ? Colors.amber : Colors.blue).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGold ? '✨ Paket Gold' : '⭐ Paket Silver',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kasir: $kasirCount${isGold ? ' (Unlimited)' : ' / 4'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Icon(
                isGold ? Icons.star_rounded : Icons.check_circle,
                color: Colors.white,
                size: 40,
              ),
            ],
          ),
          if (!isGold && limitReached) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Batas kasir tercapai. Upgrade untuk menambah.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCashierCard(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          user.username,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.badge_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[600]),
            onPressed: () => _confirmDelete(user),
            tooltip: "Hapus Kasir",
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(bool canAddMore, int kasirCount) {
    return Tooltip(
      message: canAddMore ? 'Tambah Kasir' : 'Batas kasir Silver tercapai (4)',
      child: FloatingActionButton.extended(
        onPressed: () {
          if (!canAddMore) {
            _showUpgradeDialog(kasirCount);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCashierScreen(storeId: widget.storeId),
              ),
            );
          }
        },
        backgroundColor: canAddMore ? primaryColor : Colors.grey[400],
        foregroundColor: Colors.white,
        icon: Icon(canAddMore ? Icons.add_rounded : Icons.lock_rounded),
        label: Text(
          canAddMore ? 'Tambah Kasir' : 'Batas Tercapai',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

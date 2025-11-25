import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePaymentScreen extends StatefulWidget {
  const ManagePaymentScreen({super.key});

  @override
  State<ManagePaymentScreen> createState() => _ManagePaymentScreenState();
}

class _ManagePaymentScreenState extends State<ManagePaymentScreen> {
  // Referensi ke collection Firestore
  final CollectionReference paymentMethods =
      FirebaseFirestore.instance.collection('payment_methods');

  // Fungsi Tambah/Edit
  Future<void> _showFormDialog({String? id, Map<String, dynamic>? data}) async {
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final holderController = TextEditingController(text: data?['holder'] ?? '');
    final numberController = TextEditingController(text: data?['number'] ?? '');
    String type = data?['type'] ?? 'BANK'; // BANK atau QRIS

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Tambah Metode' : 'Edit Metode'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Nama Bank / E-Wallet'),
              ),
              TextField(
                controller: holderController,
                decoration:
                    const InputDecoration(labelText: 'Atas Nama (Holder)'),
              ),
              TextField(
                controller: numberController,
                decoration:
                    const InputDecoration(labelText: 'No. Rekening / ID'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'BANK', child: Text('Transfer Bank')),
                  DropdownMenuItem(
                      value: 'QRIS', child: Text('QRIS / E-Wallet')),
                ],
                onChanged: (val) => type = val!,
                decoration: const InputDecoration(labelText: 'Tipe'),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newData = {
                'name': nameController.text,
                'holder': holderController.text,
                'number': numberController.text,
                'type': type,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (id == null) {
                // Tambah baru
                await paymentMethods.add(newData);
              } else {
                // Update
                await paymentMethods.doc(id).update(newData);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Fungsi Hapus
  void _deleteMethod(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus?'),
        content: const Text('Data ini akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              paymentMethods.doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Metode Pembayaran'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            paymentMethods.orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Terjadi Kesalahan'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return const Center(child: Text('Belum ada metode pembayaran'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final doc = data[index];
              final item = doc.data() as Map<String, dynamic>;
              final id = doc.id;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['type'] == 'QRIS'
                          ? Icons.qr_code
                          : Icons.account_balance,
                      color: Colors.green,
                    ),
                  ),
                  title: Text(
                    item['name'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${item['holder']} - ${item['number']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFormDialog(id: id, data: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMethod(id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}

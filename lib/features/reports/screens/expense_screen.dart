import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme.dart'; // Pastikan path ini benar sesuai struktur folder Anda
import '../models/expense_model.dart';
import '../services/expense_service.dart';

class ExpenseScreen extends StatefulWidget {
  final String storeId;

  const ExpenseScreen({super.key, required this.storeId});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final NumberFormat _currencyFormat =
      NumberFormat.simpleCurrency(locale: 'id_ID', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  // Menampilkan Form Tambah Pengeluaran
  void _showAddExpenseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddExpenseForm(
        storeId: widget.storeId,
        service: _expenseService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catatan Pengeluaran"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseModal(context),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Catat Pengeluaran", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenseService.getExpenses(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.money_off_csred_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Belum ada pengeluaran tercatat"),
                ],
              ),
            );
          }

          // Hitung Total Pengeluaran
          double totalExpense = expenses.fold(0, (sum, item) => sum + item.amount);

          return Column(
            children: [
              // Header Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border(bottom: BorderSide(color: Colors.red.shade100)),
                ),
                child: Column(
                  children: [
                    const Text("Total Pengeluaran (30 Hari)",
                        style: TextStyle(color: Colors.red, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(totalExpense),
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // List Pengeluaran
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final item = expenses[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Hapus Data?"),
                            content: const Text("Data pengeluaran ini akan dihapus permanen."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus")),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _expenseService.deleteExpense(item.id);
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            child: const Icon(Icons.output_rounded, color: Colors.red),
                          ),
                          title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.note.isNotEmpty) Text(item.note),
                              Text(_dateFormat.format(item.date.toDate()),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                          trailing: Text(
                            _currencyFormat.format(item.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Form Widget Terpisah agar kode rapi
class _AddExpenseForm extends StatefulWidget {
  final String storeId;
  final ExpenseService service;

  const _AddExpenseForm({required this.storeId, required this.service});

  @override
  State<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<_AddExpenseForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Operasional';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _categories = [
    'Operasional', 'Gaji Karyawan', 'Sewa Tempat', 'Beli Stok', 'Listrik & Air', 'Lain-lain'
  ];

  Future<void> _submit() async {
    if (_amountController.text.isEmpty) return;

    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      await widget.service.addExpense(
        storeId: widget.storeId,
        amount: amount,
        category: _selectedCategory,
        note: _noteController.text,
        date: _selectedDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tambah Pengeluaran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Input Nominal
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Jumlah (Rp)",
              border: OutlineInputBorder(),
              prefixText: "Rp ",
            ),
          ),
          const SizedBox(height: 16),

          // Input Kategori
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 16),

          // Input Catatan
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: "Catatan (Opsional)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          // Input Tanggal
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Tanggal"),
            subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(height: 24),

          // Tombol Simpan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class ComplaintService {
  Stream<List<ComplaintModel>> getComplaints() {
    return FirebaseFirestore.instance
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ComplaintModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateComplaintStatus(String docId, String status) {
    return FirebaseFirestore.instance
        .collection('complaints')
        .doc(docId)
        .update({
      'status': status,
    });
  }
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final ComplaintService _service = ComplaintService();
  final formatDateTime = DateFormat('dd/MM/yyyy, HH:mm');
  final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'resolved': Colors.green,
    'closed': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📢 Pengaduan Customer'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<List<ComplaintModel>>(
        stream: _service.getComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return Center(
              child: Text("Belum ada pengaduan masuk"),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = complaints[i];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  title: Text(c.subject,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text("Dari: ${c.name} (${c.email})"),
                      Text("Kategori: ${c.category}"),
                      Text("Tanggal: ${formatDateTime.format(c.createdAt)}"),
                      const SizedBox(height: 4),
                      Text(c.message),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (statusColors[c.status] ?? Colors.orange)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              c.status.toUpperCase(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      statusColors[c.status] ?? Colors.orange,
                                  fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () => _service.updateComplaintStatus(
                                c.id, 'resolved'),
                            child: const Text("Tandai Selesai"),
                          ),
                          TextButton(
                            onPressed: () =>
                                _service.updateComplaintStatus(c.id, 'closed'),
                            child: const Text("Tutup"),
                          ),
                        ],
                      ),
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
}

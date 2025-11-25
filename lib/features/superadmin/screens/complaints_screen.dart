import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status + time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (statusColors[c.status] ?? Colors.orange).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              c.status.toUpperCase(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColors[c.status] ?? Colors.orange,
                                  fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(
                            formatDateTime.format(c.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 15, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "${c.name} (${c.email})",
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category, size: 15, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            c.category,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 18),
                          Icon(Icons.label, size: 15, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            c.subject,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const Divider(height: 16, thickness: .7),
                      Text(
                        c.message,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: c.status == 'resolved'
                                ? null
                                : () => _service.updateComplaintStatus(c.id, 'resolved'),
                            icon: Icon(Icons.check_circle, color: Colors.green[700]),
                            label: Text("Tandai Selesai",
                                style: TextStyle(color: Colors.green[700])),
                          ),
                          TextButton.icon(
                            onPressed: c.status == 'closed'
                                ? null
                                : () => _service.updateComplaintStatus(c.id, 'closed'),
                            icon: Icon(Icons.close_rounded, color: Colors.red[700]),
                            label:
                                Text("Tutup", style: TextStyle(color: Colors.red[700])),
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

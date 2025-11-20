class ComplaintModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String category;
  final String subject;
  final String message;
  final DateTime createdAt;
  final String status;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.category,
    required this.subject,
    required this.message,
    required this.createdAt,
    required this.status,
  });

  factory ComplaintModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return ComplaintModel(
      id: docId,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      category: data['category'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }
}

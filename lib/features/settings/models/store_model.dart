class StoreModel {
  final String id;
  final String ownerId;
  final String name;
  final String? address;
  final String? phone;
  final DateTime? subscriptionExpiry;
  // 👇 Tambahkan field ini
  final String? subscriptionPackage;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;

  StoreModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    this.phone,
    this.subscriptionExpiry,
    // 👇 Tambahkan di constructor
    this.subscriptionPackage,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map, String id) {
    return StoreModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'],
      phone: map['phone'],
      subscriptionExpiry: map['subscriptionExpiry'] != null
          ? (map['subscriptionExpiry'] as dynamic).toDate()
          : null,
      // 👇 Tambahkan di fromMap
      subscriptionPackage: map['subscriptionPackage'],
      bankName: map['bankName'],
      accountNumber: map['accountNumber'],
      accountHolder: map['accountHolder'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'phone': phone,
      'subscriptionExpiry': subscriptionExpiry,
      // 👇 Tambahkan di toMap
      'subscriptionPackage': subscriptionPackage,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    };
  }
}

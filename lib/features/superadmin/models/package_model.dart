// lib/features/superadmin/models/package_model.dart

class PackageModel {
  final String id; // 'bronze', 'silver', 'gold'
  final String name;
  final double price;
  final List<String> features;

  PackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    return PackageModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      // Konversi aman ke double (mencegah error int vs double)
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] as double? ?? 0.0),
      // 🔥 PERBAIKAN UTAMA DI SINI:
      // Konversi aman dari List<dynamic> ke List<String>
      features: (map['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'features': features,
    };
  }
}

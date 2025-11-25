class PackageModel {
  final String id;
  final String name;
  final int price;
  final int durationDays; // Matches usage in screen
  final List<String> features;
  final bool isActive;

  PackageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.features,
    this.isActive = true,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map, String id) {
    return PackageModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toInt(),
      durationDays: (map['durationDays'] ?? 30)
          .toInt(), // Ensure this key matches Firestore
      features: List<String>.from(map['features'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'features': features,
      'isActive': isActive,
    };
  }
}

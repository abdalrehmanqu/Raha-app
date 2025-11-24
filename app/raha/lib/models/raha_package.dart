class RahaPackage {
  final dynamic id;
  final String name;
  final int durationMinutes;
  final num priceQr;
  final String description;
  final DateTime? createdAt;

  RahaPackage({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.priceQr,
    required this.description,
    this.createdAt,
  });

  factory RahaPackage.fromMap(Map<String, dynamic> map) {
    return RahaPackage(
      id: map['id'],
      name: map['name'] ?? '',
      durationMinutes: map['duration_minutes'] is int
          ? map['duration_minutes'] as int
          : int.tryParse(map['duration_minutes'].toString()) ?? 0,
      priceQr: (map['price_qr'] as num?) ?? 0,
      description: map['description'] ?? '',
      createdAt:
          map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }
}

class Pod {
  final dynamic id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String terminal;
  final bool isAvailable;
  final String type; // normal, family, vip
  final bool hasShower;
  final DateTime? createdAt;

  Pod({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.terminal,
    required this.isAvailable,
    required this.type,
    required this.hasShower,
    this.createdAt,
  });

  factory Pod.fromMap(Map<String, dynamic> map) {
    return Pod(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      terminal: map['terminal'] ?? '',
      isAvailable: map['is_available'] == true,
      type: (map['type'] ?? map['pod_type'] ?? 'normal').toString(),
      hasShower: map['has_shower'] == true,
      createdAt:
          map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }
}

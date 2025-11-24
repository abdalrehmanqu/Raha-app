class Profile {
  final String id;
  final String fullName;
  final String email;
  final DateTime? createdAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name'] ?? '',
      email: map['email'] ?? '',
      createdAt:
          map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }
}

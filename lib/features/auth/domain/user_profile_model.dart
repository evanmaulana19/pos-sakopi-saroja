class UserProfile {
  final String id;
  final String email;
  final String role; // 'kasir', 'admin', 'owner'
  final String name;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'name': name,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
    );
  }
}

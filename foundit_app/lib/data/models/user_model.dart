class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? registrationPhone;
  final String? profileImageUrl;
  final String role;
  final bool isActive;
  final List<String> favouriteItemIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.registrationPhone,
    this.profileImageUrl,
    this.role = 'user',
    this.isActive = true,
    this.favouriteItemIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final effectivePhone = registrationPhone ?? phone;
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': effectivePhone,
      'registrationPhone': effectivePhone,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'isActive': isActive,
      'favouriteItemIds': favouriteItemIds,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final regPhone = map['registrationPhone'] ?? map['phone'];

    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: regPhone,
      registrationPhone: regPhone,
      profileImageUrl: map['profileImageUrl'],
      role: map['role'] ?? 'user',
      isActive: map['isActive'] ?? true,
      favouriteItemIds: List<String>.from(map['favouriteItemIds'] ?? []),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? registrationPhone,
    String? profileImageUrl,
    String? role,
    List<String>? favouriteItemIds,
    bool? isActive,
  }) {
    final effectivePhone = registrationPhone ?? phone ?? this.registrationPhone ?? this.phone;
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: effectivePhone,
      registrationPhone: effectivePhone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      favouriteItemIds: favouriteItemIds ?? this.favouriteItemIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

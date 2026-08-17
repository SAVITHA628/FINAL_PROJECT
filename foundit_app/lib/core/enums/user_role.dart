enum UserRole {
  user,
  admin;

  String get label {
    switch (this) {
      case UserRole.user: return 'User';
      case UserRole.admin: return 'Admin';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.user,
    );
  }
}

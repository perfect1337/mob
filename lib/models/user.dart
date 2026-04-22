import 'dart:convert';

enum UserRole {
  admin,
  user;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.user:
        return 'Пользователь';
    }
  }

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
          (e) => e.toString() == role,
      orElse: () => UserRole.user,
    );
  }
}

class User {
  final int? id;
  final String email;
  final String password;
  final UserRole role;

  User({
    this.id,
    required this.email,
    required this.password,
    this.role = UserRole.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'role': role.toString(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      email: json['email'] as String,
      password: json['password'] as String,
      role: json['role'] != null
          ? UserRole.fromString(json['role'] as String)
          : UserRole.user,
    );
  }

  bool get isAdmin => role == UserRole.admin;

  bool get canCreateItems => isAdmin;

  bool get canDeleteItems => isAdmin;

  bool get canChangeItemStatus => true;

  @override
  String toString() {
    return 'User(id: $id, email: $email, role: $role)';
  }
}
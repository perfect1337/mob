import 'dart:convert';

class User {
  final String email;
  final String password;

  User({
    required this.email,
    required this.password,
  });

  // Преобразование User в JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  // Создание User из JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  @override
  String toString() {
    return 'User(email: $email)';
  }
}

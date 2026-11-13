import '../../../core/utils/json_utils.dart';

enum UserRole {
  admin('Admin'),
  kasir('Kasir');

  const UserRole(this.label);

  final String label;

  static UserRole fromValue(Object? value) =>
      value == 'admin' ? UserRole.admin : UserRole.kasir;
}

/// `User`: `{ id, name, email, role }`.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: parseInt(json['id']),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: UserRole.fromValue(json['role']),
      );

  final int id;
  final String name;
  final String email;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  /// Inisial untuk avatar, mis. "Kasir Demo" → "KD".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

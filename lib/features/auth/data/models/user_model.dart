enum UserRole {
  CITIZEN,
  AUTHORITY,
  CREW,
}

extension UserRoleExtension on UserRole {
  String get nameString {
    switch (this) {
      case UserRole.CITIZEN:
        return 'Citizen';
      case UserRole.AUTHORITY:
        return 'Authority / Officer';
      case UserRole.CREW:
        return 'Field Crew';
    }
  }

  String get valueString {
    switch (this) {
      case UserRole.CITIZEN:
        return 'CITIZEN';
      case UserRole.AUTHORITY:
        return 'AUTHORITY';
      case UserRole.CREW:
        return 'CREW';
    }
  }
}

class UserModel {
  final int id;
  final String fullName;
  final String email;
  final UserRole role;
  final bool isActive;
  final String createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.CITIZEN;
    final roleStr = json['role']?.toString().toUpperCase();
    if (roleStr == 'AUTHORITY') {
      parsedRole = UserRole.AUTHORITY;
    } else if (roleStr == 'CREW') {
      parsedRole = UserRole.CREW;
    }

    return UserModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: parsedRole,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role.valueString,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

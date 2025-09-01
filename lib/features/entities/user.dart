class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String agencyId;
  final String role;


  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.agencyId,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      agencyId: json['agencyId']?.toString() ?? '', // Convert ObjectId to String
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'password': password,
      'agencyId': agencyId,
      'role': role,
    };
  }
}

class UserLoginResponse {
  final UserModel user;
  final String token;

  UserLoginResponse({
    required this.user,
    required this.token,
  });

  factory UserLoginResponse.fromJson(Map<String, dynamic> json) {
    return UserLoginResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}

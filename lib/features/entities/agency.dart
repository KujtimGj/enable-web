class AgencyModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String logoUrl;
  final bool? externalKnowledgeBase;
  final String? onboardingStatus;
  final List<AgencyFile>? files;

  AgencyModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.logoUrl,
    this.externalKnowledgeBase,
    this.onboardingStatus,
    this.files,
  });

  factory AgencyModel.fromJson(Map<String, dynamic> json) {
    return AgencyModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      externalKnowledgeBase: json['externalKnowledgeBase'] ?? false,
      onboardingStatus: json['onboardingStatus'] ?? 'pending',
      // files: (json['files'] as List<dynamic>?)
      //     ?.map((f) => AgencyFile.fromJson(f))
      //     .toList() ??
      //     [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'logoUrl': logoUrl,
    };
  }

}

class AgencyFile {
  final String file;
  final String name;
  final int size;
  final String type;
  final String url;
  final DateTime createdAt;

  AgencyFile({
    required this.file,
    required this.name,
    required this.size,
    required this.type,
    required this.url,
    required this.createdAt,
  });

  factory AgencyFile.fromJson(Map<String, dynamic> json) {
    return AgencyFile(
      file: json['file'] ?? '',
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'name': name,
      'size': size,
      'type': type,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}


class LoginResponse {
  final AgencyModel agency;
  final String token;

  LoginResponse({
    required this.agency,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      agency: AgencyModel.fromJson(json['agency']),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agency': agency.toJson(),
      'token': token,
    };
  }
}

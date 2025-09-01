
class VICModel {
  final String? id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? nationality;
  final Map<String, dynamic>? preferences;
  final String? summary;
  final List<double>? embedding;
  final String? agencyId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VICModel({
    this.id,
    this.fullName,
    this.email,
    this.phone,
    this.nationality,
    this.preferences,
    this.summary,
    this.embedding,
    this.agencyId,
    this.createdAt,
    this.updatedAt,
  });

  VICModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? nationality,
    Map<String, dynamic>? preferences,
    String? summary,
    List<double>? embedding,
    String? agencyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VICModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nationality: nationality ?? this.nationality,
      preferences: preferences ?? this.preferences,
      summary: summary ?? this.summary,
      embedding: embedding ?? this.embedding,
      agencyId: agencyId ?? this.agencyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'nationality': nationality,
      'preferences': preferences,
      'summary': summary,
      'embedding': embedding,
      'agencyId': agencyId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory VICModel.fromJson(Map<String, dynamic> json) {
    return VICModel(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      nationality: json['nationality'],
      preferences: json['preferences'],
      summary: json['summary'],
      embedding: json['embedding'] != null
          ? List<double>.from(json['embedding'])
          : null,
      agencyId: json['agencyId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  String toString() {
    return 'VICModel(id: $id, fullName: $fullName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VICModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

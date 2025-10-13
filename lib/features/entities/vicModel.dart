
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
  final String? sourceFileName;
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
    this.sourceFileName,
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
    String? sourceFileName,
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
      sourceFileName: sourceFileName ?? this.sourceFileName,
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
      'sourceFileName': sourceFileName,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory VICModel.fromJson(Map<String, dynamic> json) {
    // Handle preferences field - it should be a Map, but might be a List in some cases
    Map<String, dynamic>? preferences;
    final prefsData = json['preferences'];
    if (prefsData is Map<String, dynamic>) {
      preferences = prefsData;
    } else if (prefsData is Map) {
      preferences = Map<String, dynamic>.from(prefsData);
    } else if (prefsData is List) {
      // If preferences is a List, convert it to an empty map or skip it
      preferences = null;
    } else if (prefsData != null) {
      preferences = null;
    }

    return VICModel(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      nationality: json['nationality'],
      preferences: preferences,
      summary: json['summary'],
      embedding: json['embedding'] != null
          ? List<double>.from(json['embedding'])
          : null,
      agencyId: json['agencyId'],
      sourceFileName: json['sourceFileName'],
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

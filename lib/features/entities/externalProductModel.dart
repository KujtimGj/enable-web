
class ExternalProductModel {
  final String? id;
  final String? agencyId;
  final String? name;
  final String? description;
  final String? category;
  final String? supplier;
  final Map<String, dynamic>? pricing;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? details;
  final Map<String, dynamic>? extras;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExternalProductModel({
    this.id,
    this.agencyId,
    this.name,
    this.description,
    this.category,
    this.supplier,
    this.pricing,
    this.location,
    this.details,
    this.extras,
    this.createdAt,
    this.updatedAt,
  });

  ExternalProductModel copyWith({
    String? id,
    String? agencyId,
    String? name,
    String? description,
    String? category,
    String? supplier,
    Map<String, dynamic>? pricing,
    Map<String, dynamic>? location,
    Map<String, dynamic>? details,
    Map<String, dynamic>? extras,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExternalProductModel(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      pricing: pricing ?? this.pricing,
      location: location ?? this.location,
      details: details ?? this.details,
      extras: extras ?? this.extras,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'agencyId': agencyId,
      'name': name,
      'description': description,
      'category': category,
      'supplier': supplier,
      'pricing': pricing,
      'location': location,
      'details': details,
      'extras': extras,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ExternalProductModel.fromJson(Map<String, dynamic> json) {
    return ExternalProductModel(
      id: json['_id'] ?? json['id'],
      agencyId: json['agencyId'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      supplier: json['supplier'],
      pricing: json['pricing'],
      location: json['location'],
      details: json['details'],
      extras: json['extras'],
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
    return 'ExternalProductModel(id: $id, name: $name, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExternalProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

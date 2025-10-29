
class ExternalProductModel {
  final String? id;
  final String? agencyId;
  final String? name;
  final String? description;
  final String? category;
  final String? supplier;
  final String? city;
  final String? country;
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
    this.city,
    this.country,
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
    String? city,
    String? country,
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
      city: city ?? this.city,
      country: country ?? this.country,
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
      'city': city,
      'country': country,
      'pricing': pricing,
      'location': location,
      'details': details,
      'extras': extras,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ExternalProductModel.fromJson(Map<String, dynamic> json) {
    // Preserve photos/images and other fields that aren't in the model in extras
    final Map<String, dynamic>? existingExtras = json['extras'] != null 
        ? Map<String, dynamic>.from(json['extras']) 
        : <String, dynamic>{};
    
    // Add photos, images, and other backend fields to extras if they exist
    if (json['photos'] != null) existingExtras!['photos'] = json['photos'];
    if (json['images'] != null) existingExtras!['images'] = json['images'];
    if (json['businessSummary'] != null) existingExtras!['businessSummary'] = json['businessSummary'];
    if (json['rating'] != null) existingExtras!['rating'] = json['rating'];
    if (json['rawData'] != null) existingExtras!['rawData'] = json['rawData'];
    
    return ExternalProductModel(
      id: json['_id'] ?? json['id'],
      agencyId: json['agencyId'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      supplier: json['supplier'],
      city: json['city'],
      country: json['country'],
      pricing: json['pricing'],
      location: json['location'],
      details: json['details'],
      extras: existingExtras!.isNotEmpty ? existingExtras : null,
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

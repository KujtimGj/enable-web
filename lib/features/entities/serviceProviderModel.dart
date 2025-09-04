
class ServiceProviderModel {
  final String? id;
  final String? agencyId;
  final String? name;
  final String? type;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? website;
  final Map<String, dynamic>? extras;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceProviderModel({
    this.id,
    this.agencyId,
    this.name,
    this.type,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.website,
    this.extras,
    this.createdAt,
    this.updatedAt,
  });

  ServiceProviderModel copyWith({
    String? id,
    String? agencyId,
    String? name,
    String? type,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? website,
    Map<String, dynamic>? extras,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceProviderModel(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      name: name ?? this.name,
      type: type ?? this.type,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      website: website ?? this.website,
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
      'type': type,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'website': website,
      'extras': extras,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    return ServiceProviderModel(
      id: json['_id'] ?? json['id'],
      agencyId: json['agencyId'],
      name: json['name'],
      type: json['type'],
      contactPerson: json['contactPerson'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      website: json['website'],
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
    return 'ServiceProviderModel(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceProviderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

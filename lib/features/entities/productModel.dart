class ProductModel {
  final String id;
  final String name;
  final String category;
  final String? subcategory;
  final String? description;
  final String? country;
  final String? city;
  final double? lat;
  final double? lng;
  final Map<String, dynamic>? tags;
  final String? providerName;
  final String? providerWebsite;
  final String? providerContact;
  final List<MediaPhoto>? mediaPhotos;
  final double? rating;
  final String? availability;
  final double? priceMin;
  final double? priceMax;
  final Map<String, dynamic>? features;
  final List<double> embedding;
  final String agencyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    this.description,
    this.country,
    this.city,
    this.lat,
    this.lng,
    this.tags,
    this.providerName,
    this.providerWebsite,
    this.providerContact,
    this.mediaPhotos,
    this.rating,
    this.availability,
    this.priceMin,
    this.priceMax,
    this.features,
    required this.embedding,
    required this.agencyId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'],
      name: json['name'],
      category: json['category'],
      subcategory: json['subcategory'],
      description: json['description'],
      country: json['country'],
      city: json['city'],
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      tags: Map<String, dynamic>.from(json['tags'] ?? {}),
      providerName: json['providerName'],
      providerWebsite: json['providerWebsite'],
      providerContact: json['providerContact'],
      mediaPhotos: (json['mediaPhotos'] as List?)
          ?.map((e) => MediaPhoto.fromJson(e))
          .toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      availability: json['availability'],
      priceMin: (json['priceMin'] as num?)?.toDouble(),
      priceMax: (json['priceMax'] as num?)?.toDouble(),
      features: Map<String, dynamic>.from(json['features'] ?? {}),
      embedding: List<double>.from((json['embedding'] ?? []).map((e) => e.toDouble())),
      agencyId: json['agencyId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class MediaPhoto {
  final String? imageUrl;
  final String? signedUrl;

  MediaPhoto({this.imageUrl, this.signedUrl});

  factory MediaPhoto.fromJson(Map<String, dynamic> json) {
    return MediaPhoto(
      imageUrl: json['imageUrl'],
      signedUrl: json['signedUrl'],
    );
  }
}

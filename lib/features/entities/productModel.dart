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
  final List<MediaPhoto>? images;
  final double? rating;
  final String? availability;
  final double? priceMin;
  final double? priceMax;
  final dynamic features; // Changed to dynamic to handle both array and object
  final List<double>? embedding; // Made nullable since it might not always be present
  final String agencyId;
  final DateTime? createdAt; // Made nullable
  final DateTime? updatedAt; // Made nullable

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
    this.images,
    this.rating,
    this.availability,
    this.priceMin,
    this.priceMax,
    this.features,
    this.embedding,
    required this.agencyId,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subcategory: json['subcategory']?.toString(),
      description: json['description']?.toString(),
      country: json['country']?.toString(),
      city: json['city']?.toString(),
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      tags: _parseTags(json['tags']),
      providerName: json['providerName']?.toString(),
      providerWebsite: json['providerWebsite']?.toString(),
      providerContact: json['providerContact']?.toString(),
      images: _parseMediaPhotos(json['images']),
      rating: _parseDouble(json['rating']),
      availability: json['availability']?.toString(),
      priceMin: _parseDouble(json['priceMin']),
      priceMax: _parseDouble(json['priceMax']),
      features: json['features'], // Keep as dynamic to handle both types
      embedding: _parseEmbedding(json['embedding']),
      agencyId: json['agencyId']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  // Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper method to safely parse tags
  static Map<String, dynamic>? _parseTags(dynamic tags) {
    if (tags == null) return null;
    if (tags is Map<String, dynamic>) return tags;
    if (tags is Map) {
      // Convert any Map to Map<String, dynamic>
      return Map<String, dynamic>.from(tags);
    }
    return null;
  }

  // Helper method to safely parse media photos
  static List<MediaPhoto>? _parseMediaPhotos(dynamic images) {
    if (images == null) return null;
    if (images is List) {
      return images
          .where((item) => item is Map<String, dynamic>)
          .map((item) => MediaPhoto.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  // Helper method to safely parse embedding
  static List<double>? _parseEmbedding(dynamic embedding) {
    if (embedding == null) return null;
    if (embedding is List) {
      return embedding
          .where((item) => item != null)
          .map((item) => _parseDouble(item))
          .where((item) => item != null)
          .cast<double>()
          .toList();
    }
    return null;
  }

  // Helper method to safely parse DateTime
  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'country': country,
      'city': city,
      'lat': lat,
      'lng': lng,
      'tags': tags,
      'providerName': providerName,
      'providerWebsite': providerWebsite,
      'providerContact': providerContact,
      'images': images?.map((photo) => photo.toJson()).toList(),
      'rating': rating,
      'availability': availability,
      'priceMin': priceMin,
      'priceMax': priceMax,
      'features': features,
      'embedding': embedding,
      'agencyId': agencyId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class MediaPhoto {
  final String? imageUrl;
  final String? signedUrl;

  MediaPhoto({this.imageUrl, this.signedUrl});

  factory MediaPhoto.fromJson(Map<String, dynamic> json) {
    return MediaPhoto(
      imageUrl: json['imageUrl']?.toString(),
      signedUrl: json['signedUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'signedUrl': signedUrl,
    };
  }
}

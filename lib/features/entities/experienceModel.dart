
class ItineraryItemModel {
  final int? day;
  final int? order;
  final String? type;
  final String? status;
  final DateTime? startAt;
  final DateTime? endAt;
  final Map<String, dynamic>? productRef;
  final Map<String, dynamic>? supplier;
  final Map<String, dynamic>? price;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? details;
  final Map<String, dynamic>? extras;
  final Map<String, dynamic>? snapshot;

  ItineraryItemModel({
    this.day,
    this.order,
    this.type,
    this.status,
    this.startAt,
    this.endAt,
    this.productRef,
    this.supplier,
    this.price,
    this.location,
    this.details,
    this.extras,
    this.snapshot,
  });

  ItineraryItemModel copyWith({
    int? day,
    int? order,
    String? type,
    String? status,
    DateTime? startAt,
    DateTime? endAt,
    Map<String, dynamic>? productRef,
    Map<String, dynamic>? supplier,
    Map<String, dynamic>? price,
    Map<String, dynamic>? location,
    Map<String, dynamic>? details,
    Map<String, dynamic>? extras,
    Map<String, dynamic>? snapshot,
  }) {
    return ItineraryItemModel(
      day: day ?? this.day,
      order: order ?? this.order,
      type: type ?? this.type,
      status: status ?? this.status,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      productRef: productRef ?? this.productRef,
      supplier: supplier ?? this.supplier,
      price: price ?? this.price,
      location: location ?? this.location,
      details: details ?? this.details,
      extras: extras ?? this.extras,
      snapshot: snapshot ?? this.snapshot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'order': order,
      'type': type,
      'status': status,
      'startAt': startAt?.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'productRef': productRef,
      'supplier': supplier,
      'price': price,
      'location': location,
      'details': details,
      'extras': extras,
      'snapshot': snapshot,
    };
  }

  factory ItineraryItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return ItineraryItemModel(
        day: json['day'] != null ? json['day'] as int : null,
        order: json['order'] != null ? json['order'] as int : null,
        type: json['type'],
        status: json['status'],
        startAt: json['startAt'] != null 
            ? DateTime.parse(json['startAt']) 
            : null,
        endAt: json['endAt'] != null 
            ? DateTime.parse(json['endAt']) 
            : null,
        productRef: json['productRef'] != null ? Map<String, dynamic>.from(json['productRef']) : null,
        supplier: json['supplier'] != null ? Map<String, dynamic>.from(json['supplier']) : null,
        price: json['price'] != null ? Map<String, dynamic>.from(json['price']) : null,
        location: json['location'] != null ? Map<String, dynamic>.from(json['location']) : null,
        details: json['details'] != null ? Map<String, dynamic>.from(json['details']) : null,
        extras: json['extras'] != null ? Map<String, dynamic>.from(json['extras']) : null,
        snapshot: json['snapshot'] != null ? Map<String, dynamic>.from(json['snapshot']) : null,
      );
    } catch (e) {
      print('Error parsing ItineraryItemModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class ExperienceModel {
  final String? id;
  final String? agencyId;
  final String? vicId;
  final String? destination;
  final String? country;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? party;
  final String? status;
  final String? notes;
  final Map<String, dynamic>? tags;
  final Map<String, dynamic>? extras;
  final Map<String, dynamic>? totals;
  final List<ItineraryItemModel>? itinerary;
  final String? feedback;
  final int? rating;
  final double? totalSpent;
  final List<double>? embedding;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExperienceModel({
    this.id,
    this.agencyId,
    this.vicId,
    this.destination,
    this.country,
    this.startDate,
    this.endDate,
    this.party,
    this.status,
    this.notes,
    this.tags,
    this.extras,
    this.totals,
    this.itinerary,
    this.feedback,
    this.rating,
    this.totalSpent,
    this.embedding,
    this.createdAt,
    this.updatedAt,
  });

  ExperienceModel copyWith({
    String? id,
    String? agencyId,
    String? vicId,
    String? destination,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? party,
    String? status,
    String? notes,
    Map<String, dynamic>? tags,
    Map<String, dynamic>? extras,
    Map<String, dynamic>? totals,
    List<ItineraryItemModel>? itinerary,
    String? feedback,
    int? rating,
    double? totalSpent,
    List<double>? embedding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExperienceModel(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      vicId: vicId ?? this.vicId,
      destination: destination ?? this.destination,
      country: country ?? this.country,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      party: party ?? this.party,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      extras: extras ?? this.extras,
      totals: totals ?? this.totals,
      itinerary: itinerary ?? this.itinerary,
      feedback: feedback ?? this.feedback,
      rating: rating ?? this.rating,
      totalSpent: totalSpent ?? this.totalSpent,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'agencyId': agencyId,
      'vicId': vicId,
      'destination': destination,
      'country': country,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'party': party,
      'status': status,
      'notes': notes,
      'tags': tags,
      'extras': extras,
      'totals': totals,
      'itinerary': itinerary?.map((item) => item.toJson()).toList(),
      'feedback': feedback,
      'rating': rating,
      'totalSpent': totalSpent,
      'embedding': embedding,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    try {
      return ExperienceModel(
        id: json['_id'] ?? json['id'],
        agencyId: json['agencyId']?.toString(),
        vicId: json['vicId']?.toString(),
        destination: json['destination'],
        country: json['country'],
        startDate: json['startDate'] != null 
            ? DateTime.parse(json['startDate']) 
            : null,
        endDate: json['endDate'] != null 
            ? DateTime.parse(json['endDate']) 
            : null,
        party: json['party'] != null ? {
          'adults': json['party']['adults'] ?? 0,
          'children': json['party']['children'] ?? 0,
        } : null,
        status: json['status'],
        notes: json['notes'],
        tags: json['tags'] != null ? Map<String, dynamic>.from(json['tags']) : null,
        extras: json['extras'] != null ? Map<String, dynamic>.from(json['extras']) : null,
        totals: json['totals'] != null ? Map<String, dynamic>.from(json['totals']) : null,
        itinerary: json['itinerary'] != null 
            ? (json['itinerary'] as List)
                .map((item) => ItineraryItemModel.fromJson(item))
                .toList()
            : null,
        feedback: json['feedback'],
        rating: json['rating'] != null ? json['rating'] as int : null,
        totalSpent: json['totalSpent'] != null ? json['totalSpent'].toDouble() : null,
        embedding: json['embedding'] != null 
            ? (json['embedding'] as List).map((item) => item?.toDouble()).whereType<double>().toList()
            : null,
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : null,
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt']) 
            : null,
      );
    } catch (e) {
      print('Error parsing ExperienceModel from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'ExperienceModel(id: $id, destination: $destination, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExperienceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

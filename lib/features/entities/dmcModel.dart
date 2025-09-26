class DMC {
  final String id;
  final String businessName;
  final String? location;
  final String? description;
  final String? pointOfContact;
  final String? serviceProviders;
  final String agencyId;
  final String? sourceFileName;

  DMC({
    required this.id,
    required this.businessName,
    this.location,
    this.description,
    this.pointOfContact,
    this.serviceProviders,
    required this.agencyId,
    this.sourceFileName,
  });

  factory DMC.fromJson(Map<String, dynamic> json) {
    return DMC(
      id: json['_id'],
      businessName: json['businessName'],
      location: json['location'],
      description: json['description'],
      pointOfContact: json['pointOfContact'],
      serviceProviders: json['serviceProviders'],
      agencyId: json['agencyId'],
      sourceFileName: json['sourceFileName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessName': businessName,
      'location': location,
      'description': description,
      'pointOfContact': pointOfContact,
      'serviceProviders': serviceProviders,
      'agencyId': agencyId,
      'sourceFileName': sourceFileName,
    };
  }
}

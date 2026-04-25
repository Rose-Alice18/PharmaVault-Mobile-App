class PharmacyModel {
  final String  customerId;
  final String  customerName;
  final String? customerCity;
  final String? customerContact;
  final String? customerImage;
  final double? lat;
  final double? lng;

  PharmacyModel({
    required this.customerId,
    required this.customerName,
    this.customerCity,
    this.customerContact,
    this.customerImage,
    this.lat,
    this.lng,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      customerId:      (json['id'] ?? json['customer_id']).toString(),
      customerName:    json['customer_name'] as String,
      customerCity:    json['customer_city'] as String?,
      customerContact: json['customer_contact'] as String?,
      customerImage:   json['customer_image'] as String?,
      lat:             (json['lat'] as num?)?.toDouble(),
      lng:             (json['lng'] as num?)?.toDouble(),
    );
  }
}

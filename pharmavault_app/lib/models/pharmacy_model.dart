class PharmacyModel {
  final String customerId;   // UUID in Supabase (auth.users id)
  final String customerName;
  final String? customerCity;
  final String? customerContact;
  final String? customerImage;

  PharmacyModel({
    required this.customerId,
    required this.customerName,
    this.customerCity,
    this.customerContact,
    this.customerImage,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      // Supabase profiles table uses 'id' (UUID); legacy PHP used 'customer_id' (int)
      customerId:      (json['id'] ?? json['customer_id']).toString(),
      customerName:    json['customer_name'] as String,
      customerCity:    json['customer_city'] as String?,
      customerContact: json['customer_contact'] as String?,
      customerImage:   json['customer_image'] as String?,
    );
  }
}

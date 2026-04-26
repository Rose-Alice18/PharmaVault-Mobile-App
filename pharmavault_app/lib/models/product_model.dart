class ProductModel {
  final int productId;
  final String productTitle;
  final String productDescription;
  final double productPrice;
  final int productStock;
  final String? productImage;
  final String? productKeywords;
  final int? productCat;
  final int? productBrand;
  final String? catName;
  final String? brandName;

  ProductModel({
    required this.productId,
    required this.productTitle,
    required this.productDescription,
    required this.productPrice,
    required this.productStock,
    this.productImage,
    this.productKeywords,
    this.productCat,
    this.productBrand,
    this.catName,
    this.brandName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Supabase returns nested objects for joined tables, e.g. json['categories']['cat_name']
    final cat   = json['categories'] as Map<String, dynamic>?;
    final brand = json['brands']     as Map<String, dynamic>?;
    return ProductModel(
      productId:          json['product_id'] as int,
      productTitle:       json['product_title'] as String,
      productDescription: json['product_description'] as String? ?? '',
      productPrice:       double.tryParse(json['product_price'].toString()) ?? 0.0,
      productStock:       json['product_stock'] as int? ?? 0,
      productImage:       json['product_image'] as String?,
      productKeywords:    json['product_keywords'] as String?,
      productCat:         json['cat_id'] as int?,
      productBrand:       json['brand_id'] as int?,
      catName:            json['cat_name'] as String? ?? cat?['cat_name'] as String?,
      brandName:          json['brand_name'] as String? ?? brand?['brand_name'] as String?,
    );
  }
}

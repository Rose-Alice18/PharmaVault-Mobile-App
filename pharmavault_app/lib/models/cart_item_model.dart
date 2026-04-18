class CartItemModel {
  final int productId;
  int qty;
  final String productTitle;
  final double productPrice;
  final String? productImage;
  final int productStock;
  final double lineTotal;
  final String? catName;
  final String? brandName;

  CartItemModel({
    required this.productId,
    required this.qty,
    required this.productTitle,
    required this.productPrice,
    this.productImage,
    required this.productStock,
    required this.lineTotal,
    this.catName,
    this.brandName,
  });

  /// Handles both the Supabase nested format:
  ///   { cart_qty: 2, products: { product_id: 5, product_title: "...", ... } }
  /// and the flat format used in tests / legacy code.
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final p   = json['products'] as Map<String, dynamic>?;
    final qty = json['cart_qty'] as int? ?? json['qty'] as int? ?? 1;
    final price = double.tryParse(
          (p?['product_price'] ?? json['product_price']).toString(),
        ) ??
        0.0;
    return CartItemModel(
      productId:    p?['product_id'] as int? ?? json['product_id'] as int,
      qty:          qty,
      productTitle: p?['product_title'] as String? ?? json['product_title'] as String? ?? '',
      productPrice: price,
      productImage: p?['product_image'] as String? ?? json['product_image'] as String?,
      productStock: p?['product_stock'] as int? ?? json['product_stock'] as int? ?? 0,
      lineTotal:    price * qty,
      catName:      p?['cat_name'] as String? ?? json['cat_name'] as String?,
      brandName:    p?['brand_name'] as String? ?? json['brand_name'] as String?,
    );
  }
}

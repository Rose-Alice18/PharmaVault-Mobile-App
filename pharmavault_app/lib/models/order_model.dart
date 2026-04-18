class OrderModel {
  final int orderId;
  final String invoiceNo;   // Changed from int → String for Supabase text field
  final String orderDate;
  final String orderStatus;
  final String? deliveryMethod;
  final String? deliveryNotes;
  final double paymentAmount;
  final bool isPaid;
  final double orderTotal;

  OrderModel({
    required this.orderId,
    required this.invoiceNo,
    required this.orderDate,
    required this.orderStatus,
    this.deliveryMethod,
    this.deliveryNotes,
    required this.paymentAmount,
    required this.isPaid,
    required this.orderTotal,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId:        json['order_id'] as int,
      invoiceNo:      json['invoice_no'].toString(),
      orderDate:      json['order_date'] as String? ?? '',
      orderStatus:    json['order_status'] as String? ?? 'pending',
      deliveryMethod: json['delivery_method'] as String?,
      deliveryNotes:  json['delivery_notes'] as String?,
      paymentAmount:  double.tryParse(json['payment_amount']?.toString() ?? '0') ?? 0.0,
      isPaid:         json['is_paid'] == true || json['is_paid'] == 1,
      orderTotal:     double.tryParse(json['order_total'].toString()) ?? 0.0,
    );
  }
}

class OrderItemModel {
  final int productId;
  final int qty;
  final String productTitle;
  final double productPrice;
  final String? productImage;
  final double lineTotal;
  final String? catName;
  final String? brandName;

  OrderItemModel({
    required this.productId,
    required this.qty,
    required this.productTitle,
    required this.productPrice,
    this.productImage,
    required this.lineTotal,
    this.catName,
    this.brandName,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId:    json['product_id'] as int,
      qty:          json['qty'] as int,
      productTitle: json['product_title'] as String? ?? '',
      productPrice: double.tryParse(json['product_price'].toString()) ?? 0.0,
      productImage: json['product_image'] as String?,
      lineTotal:    double.tryParse(json['line_total'].toString()) ?? 0.0,
      catName:      json['cat_name'] as String?,
      brandName:    json['brand_name'] as String?,
    );
  }
}

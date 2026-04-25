import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/supabase_constants.dart';
import '../models/order_model.dart';
import '../services/notification_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel>     _orders        = [];
  OrderModel?          _selectedOrder;
  List<OrderItemModel> _selectedItems = [];
  double               _selectedTotal = 0.0;
  bool                 _isLoading     = false;
  String?              _error;

  List<OrderModel>     get orders        => _orders;
  OrderModel?          get selectedOrder => _selectedOrder;
  List<OrderItemModel> get selectedItems => _selectedItems;
  double               get selectedTotal => _selectedTotal;
  bool                 get isLoading     => _isLoading;
  String?              get error         => _error;

  final _db = SupabaseConstants.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<void> fetchOrders() async {
    if (_uid == null) { _orders = []; notifyListeners(); return; }
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final raw = await _db
          .from('orders')
          .select()
          .eq('c_id', _uid!)
          .order('order_date', ascending: false);

      _orders = (raw as List)
          .map((row) => OrderModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to load orders.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOrderById(int orderId) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      // Fetch the order
      final orderRow = await _db
          .from('orders')
          .select()
          .eq('order_id', orderId)
          .single();
      _selectedOrder = OrderModel.fromJson(orderRow);

      // Fetch items with product join
      final itemsRaw = await _db
          .from('order_items')
          .select('*, products(product_id, product_title, product_price, product_image, categories(cat_name), brands(brand_name))')
          .eq('order_id', orderId);

      _selectedItems = (itemsRaw as List).map((row) {
        final r  = row as Map<String, dynamic>;
        final p  = r['products'] as Map<String, dynamic>? ?? {};
        final qty = r['item_qty'] as int? ?? 1;
        final price = double.tryParse(r['item_price'].toString()) ?? 0.0;
        return OrderItemModel(
          productId:    p['product_id'] as int? ?? 0,
          qty:          qty,
          productTitle: p['product_title'] as String? ?? '',
          productPrice: price,
          productImage: p['product_image'] as String?,
          lineTotal:    price * qty,
          catName:      (p['categories'] as Map<String, dynamic>?)?['cat_name'] as String?,
          brandName:    (p['brands']     as Map<String, dynamic>?)?['brand_name'] as String?,
        );
      }).toList();

      _selectedTotal = _selectedItems.fold(0.0, (s, i) => s + i.lineTotal);
    } catch (e) {
      _error = 'Failed to load order details.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createOrder({
    required String address,
    required String city,
    required String contact,
    bool isPaid = false,
    double paymentAmount = 0.0,
    String? paymentReference,
  }) async {
    if (_uid == null) { _error = 'Not logged in.'; notifyListeners(); return null; }
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      // 1. Fetch current cart from Supabase
      final cartRaw = await _db
          .from('cart')
          .select('cart_qty, product_id, products(product_price)')
          .eq('c_id', _uid!);

      final cartItems = cartRaw as List;
      if (cartItems.isEmpty) {
        _error     = 'Your cart is empty.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // 2. Calculate total
      double total = 0.0;
      for (final item in cartItems) {
        final price = double.tryParse(
              (item['products'] as Map<String, dynamic>?)?['product_price'].toString() ?? '0',
            ) ??
            0.0;
        total += price * (item['cart_qty'] as int);
      }

      // 3. Generate invoice number
      final ts = DateTime.now();
      final invoiceNo = 'INV-${ts.year}-${ts.millisecondsSinceEpoch.toString().substring(7)}';

      // 4. Insert order row
      final deliveryNotes = jsonEncode({
        'address': address,
        'city':    city,
        'contact': contact,
      });

      final orderRes = await _db.from('orders').insert({
        'invoice_no':      invoiceNo,
        'c_id':            _uid,
        'order_total':     total,
        'order_status':    'pending',
        'delivery_notes':  deliveryNotes,
        'payment_amount':  paymentAmount,
        'is_paid':         isPaid,
      }).select().single();

      final orderId = orderRes['order_id'] as int;

      // 5. Insert order items
      final itemRows = cartItems.map((item) {
        final price = double.tryParse(
              (item['products'] as Map<String, dynamic>?)?['product_price'].toString() ?? '0',
            ) ??
            0.0;
        return {
          'order_id':  orderId,
          'product_id': item['product_id'] as int,
          'item_qty':  item['cart_qty'] as int,
          'item_price': price,
        };
      }).toList();
      await _db.from('order_items').insert(itemRows);

      // 6. Clear cart
      await _db.from('cart').delete().eq('c_id', _uid!);

      _isLoading = false;
      notifyListeners();
      await fetchOrders();
      await NotificationService.showOrderPlaced(invoiceNo: invoiceNo);

      return {
        'invoice_no':        invoiceNo,
        'order_id':          orderId,
        'item_count':        cartItems.length,
        'status':            'pending',
        'is_paid':           isPaid,
        'payment_reference': paymentReference,
      };
    } catch (e) {
      _error     = 'Failed to place order. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

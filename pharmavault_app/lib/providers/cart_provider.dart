import 'package:flutter/foundation.dart';
import '../constants/supabase_constants.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  List<CartItemModel> _items     = [];
  bool                _isLoading = false;
  String?             _error;

  List<CartItemModel> get items      => _items;
  double get cartTotal => _items.fold(0.0, (sum, i) => sum + i.lineTotal);
  int    get itemCount => _items.fold(0,   (sum, i) => sum + i.qty);
  bool   get isLoading => _isLoading;
  String? get error    => _error;
  bool   get isEmpty   => _items.isEmpty;

  final _db = SupabaseConstants.client;

  String? get _uid => _db.auth.currentUser?.id;

  Future<void> fetchCart() async {
    if (_uid == null) { _items = []; notifyListeners(); return; }
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final raw = await _db
          .from('cart')
          .select('*, products(product_id, product_title, product_price, product_stock, product_image, product_keywords)')
          .eq('c_id', _uid!);

      _items = (raw as List)
          .map((row) => CartItemModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to load cart.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addItem(int productId, {int qty = 1}) async {
    if (_uid == null) return false;
    try {
      // Upsert: if row exists, add qty; otherwise insert
      final existing = await _db
          .from('cart')
          .select('cart_id, cart_qty')
          .eq('c_id', _uid!)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        final newQty = (existing['cart_qty'] as int) + qty;
        await _db
            .from('cart')
            .update({'cart_qty': newQty})
            .eq('cart_id', existing['cart_id'] as int);
      } else {
        await _db.from('cart').insert({
          'product_id':     productId,
          'c_id':     _uid,
          'cart_qty': qty,
        });
      }
      await fetchCart();
      return true;
    } catch (e) {
      _error = 'Failed to add item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(int productId, int qty) async {
    if (_uid == null) return false;
    try {
      await _db
          .from('cart')
          .update({'cart_qty': qty})
          .eq('c_id', _uid!)
          .eq('product_id', productId);
      await fetchCart();
      return true;
    } catch (e) {
      _error = 'Failed to update item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeItem(int productId) async {
    if (_uid == null) return false;
    try {
      await _db
          .from('cart')
          .delete()
          .eq('c_id', _uid!)
          .eq('product_id', productId);
      await fetchCart();
      return true;
    } catch (e) {
      _error = 'Failed to remove item.';
      notifyListeners();
      return false;
    }
  }

  void clearLocalCart() {
    _items = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

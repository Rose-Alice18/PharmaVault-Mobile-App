import 'package:flutter/foundation.dart';
import '../constants/supabase_constants.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel>  _products   = [];
  List<CategoryModel> _categories = [];
  ProductModel?       _selected;
  bool                _isLoading  = false;
  String?             _error;

  List<ProductModel>  get products   => _products;
  List<CategoryModel> get categories => _categories;
  ProductModel?       get selected   => _selected;
  bool                get isLoading  => _isLoading;
  String?             get error      => _error;

  final _db = SupabaseConstants.client;

  Future<void> fetchProducts({
    String? search,
    int?    catId,
    int?    brandId,
    int?    limit,
  }) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      var query = _db
          .from('products')
          .select('*, categories(cat_name), brands(brand_name)');

      if (search != null && search.isNotEmpty) {
        query = query.ilike('product_title', '%$search%');
      }
      if (catId   != null) query = query.eq('product_cat',   catId);
      if (brandId != null) query = query.eq('product_brand', brandId);

      final raw = limit != null ? await query.limit(limit) : await query;
      _products = (raw as List)
          .map((row) => ProductModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to load products.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProductById(int id) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final row = await _db
          .from('products')
          .select('*, categories(cat_name), brands(brand_name)')
          .eq('product_id', id)
          .single();
      _selected = ProductModel.fromJson(row);
    } catch (e) {
      _error = 'Failed to load product.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    if (_categories.isNotEmpty) return;
    try {
      final raw = await _db.from('categories').select();
      _categories = (raw as List)
          .map((row) => CategoryModel.fromJson(row as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

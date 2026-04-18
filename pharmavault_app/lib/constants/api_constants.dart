class ApiConstants {
  // ─────────────────────────────────────────────────────────────────────────
  // HOW TO START THE API SERVER (from the project root):
  //   php -S 0.0.0.0:8080 router.php
  //
  // For Android emulator  → use 10.0.2.2  (maps to your PC's localhost)
  // For physical device   → use your PC's local IP, e.g. 192.168.1.105
  // ─────────────────────────────────────────────────────────────────────────
  static const String _host = 'http://10.0.2.2:8080';

  static const String baseUrl = '$_host/api/v1';
  static const String imageBaseUrl = _host;

  // Auth
  static const String login    = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';

  // Products
  static const String products    = '$baseUrl/products';
  static const String productShow = '$baseUrl/products/show';

  // Categories
  static const String categories = '$baseUrl/categories';

  // Brands
  static const String brands = '$baseUrl/brands';

  // Pharmacies
  static const String pharmacies = '$baseUrl/pharmacies';

  // Cart
  static const String cart       = '$baseUrl/cart';
  static const String cartAdd    = '$baseUrl/cart/add';
  static const String cartUpdate = '$baseUrl/cart/update';
  static const String cartRemove = '$baseUrl/cart/remove';

  // Orders
  static const String orders      = '$baseUrl/orders';
  static const String orderShow   = '$baseUrl/orders/show';
  static const String orderCreate = '$baseUrl/orders/create';

  // Prescriptions
  static const String prescriptions       = '$baseUrl/prescriptions';
  static const String prescriptionUpload  = '$baseUrl/prescriptions/upload';

  // Build full image URL from a relative path returned by the API
  static String imageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;
    return '$imageBaseUrl/$relativePath';
  }
}

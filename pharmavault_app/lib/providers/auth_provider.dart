import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class AuthProvider extends ChangeNotifier {
  String? _customerName;
  String? _customerEmail;
  bool    _isLoading = false;
  String? _error;

  String? get customerName  => _customerName;
  String? get customerEmail => _customerEmail;
  bool    get isLoading     => _isLoading;
  String? get error         => _error;
  bool    get isLoggedIn    => SupabaseConstants.client.auth.currentUser != null;
  String? get userId        => SupabaseConstants.client.auth.currentUser?.id;

  /// Called once at app start — restores any persisted session.
  Future<void> initialize() async {
    final user = SupabaseConstants.client.auth.currentUser;
    if (user != null) {
      await _loadProfile(user.id);
    }
    notifyListeners();
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final data = await SupabaseConstants.client
          .from('profiles')
          .select('customer_name, customer_email')
          .eq('id', uid)
          .single();
      _customerName  = data['customer_name'] as String?;
      _customerEmail = data['customer_email'] as String?;
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final res = await SupabaseConstants.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) await _loadProfile(res.user!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error     = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error     = 'Could not connect. Check your internet connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String contact,
    required String country,
    required String city,
  }) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final res = await SupabaseConstants.client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user == null) {
        _error     = 'Registration failed. Try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      // Insert profile row with extra user data
      await SupabaseConstants.client.from('profiles').insert({
        'id':               res.user!.id,
        'customer_name':    name,
        'customer_email':   email,
        'customer_type':    'customer',
        'customer_contact': contact,
        'customer_city':    city,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error     = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error     = 'Registration error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SupabaseConstants.client.auth.signOut();
    _customerName  = null;
    _customerEmail = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class AuthProvider extends ChangeNotifier {
  String? _customerName;
  String? _customerEmail;
  String? _customerContact;
  String? _customerCity;
  String? _customerImage;
  String _customerType = 'customer';
  bool _isLoading = false;
  String? _error;

  String? get customerName => _customerName;
  String? get customerEmail => _customerEmail;
  String? get customerContact => _customerContact;
  String? get customerCity => _customerCity;
  String? get customerImage => _customerImage;
  String get customerType => _customerType;
  bool get isPharmacy => _customerType == 'pharmacy';
  bool get isPendingPharmacy => _customerType == 'pharmacy_pending';
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => SupabaseConstants.client.auth.currentUser != null;
  String? get userId => SupabaseConstants.client.auth.currentUser?.id;

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
          .select(
            'customer_name, customer_email, customer_contact, customer_city, customer_image, customer_type',
          )
          .eq('id', uid)
          .single();
      _customerName = data['customer_name'] as String?;
      _customerEmail = data['customer_email'] as String?;
      _customerContact = data['customer_contact'] as String?;
      _customerCity = data['customer_city'] as String?;
      _customerImage = data['customer_image'] as String?;
      _customerType = data['customer_type'] as String? ?? 'customer';
    } catch (_) {}
  }

  Future<bool> updateProfile({
    required String name,
    required String contact,
    required String city,
  }) async {
    if (userId == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await SupabaseConstants.client
          .from('profiles')
          .update({
            'customer_name': name,
            'customer_contact': contact,
            'customer_city': city,
          })
          .eq('id', userId!);
      _customerName = name;
      _customerContact = contact;
      _customerCity = city;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Failed to update profile.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfilePhoto() async {
    if (userId == null) return false;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final file = File(picked.path);
      final ext = picked.path.split('.').last.toLowerCase();
      final contentType = _normalizeImageMimeType(ext);
      // Path is just userId.ext — storage.from('avatars') already targets the bucket
      final path = '$userId.$ext';
      final storage = SupabaseConstants.client.storage;

      await storage
          .from('avatars')
          .upload(
            path,
            file,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      final url = storage.from('avatars').getPublicUrl(path);
      await SupabaseConstants.client
          .from('profiles')
          .update({'customer_image': url})
          .eq('id', userId!);
      _customerImage = url;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error =
          'Photo upload failed: ${e.toString().replaceAll('Exception: ', '')}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await SupabaseConstants.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not update password. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
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
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not connect. Check your internet connection.';
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
    bool isPharmacyRegistration = false,
    String? licenseNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await SupabaseConstants.client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user == null) {
        _error = 'Registration failed. Try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final profileData = <String, dynamic>{
        'id': res.user!.id,
        'customer_name': name,
        'customer_email': email.toLowerCase(),
        'customer_type': isPharmacyRegistration
            ? 'pharmacy_pending'
            : 'customer',
        'customer_contact': contact,
        'customer_city': city,
      };
      if (licenseNumber != null && licenseNumber.isNotEmpty) {
        profileData['license_number'] = licenseNumber;
      }
      await SupabaseConstants.client.from('profiles').upsert(profileData);
      _customerName = name;
      _customerEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration error. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConstants.googleClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _error = 'Google sign in failed — no ID token received.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final res = await SupabaseConstants.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      if (res.user != null) {
        // Create profile row if this is the first Google sign-in
        final existing = await SupabaseConstants.client
            .from('profiles')
            .select()
            .eq('id', res.user!.id)
            .maybeSingle();

        if (existing == null) {
          await SupabaseConstants.client.from('profiles').insert({
            'id': res.user!.id,
            'customer_name':
                googleUser.displayName ?? googleUser.email.split('@').first,
            'customer_email': googleUser.email,
            'customer_type': 'customer',
          });
        }
        await _loadProfile(res.user!.id);
      }

      _isLoading = false;
      notifyListeners();
      return res.user != null;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Google sign in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await SupabaseConstants.client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SupabaseConstants.client.auth.signOut();
    _customerName = null;
    _customerEmail = null;
    _customerContact = null;
    _customerCity = null;
    _customerImage = null;
    _customerType = 'customer';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _normalizeImageMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

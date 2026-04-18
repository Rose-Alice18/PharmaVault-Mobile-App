import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences.
/// Auth session management is handled automatically by supabase_flutter.
class StorageService {
  static const String _onboardingKey = 'onboarding_seen';

  Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}

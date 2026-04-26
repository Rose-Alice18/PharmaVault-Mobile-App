import 'package:supabase_flutter/supabase_flutter.dart';

class PharmacyBookmarkService {
  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => _db.auth.currentUser?.id;

  static Future<List<String>> getSavedIds() async {
    if (_uid == null) return [];
    try {
      final data = await _db
          .from('saved_pharmacies')
          .select('pharmacy_id')
          .eq('user_id', _uid!);
      return (data as List).map((e) => e['pharmacy_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isSaved(String id) async {
    if (_uid == null) return false;
    try {
      final data = await _db
          .from('saved_pharmacies')
          .select('id')
          .eq('user_id', _uid!)
          .eq('pharmacy_id', id)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  /// Toggles the bookmark. Returns true if now saved, false if removed.
  static Future<bool> toggle(String id) async {
    if (_uid == null) return false;
    try {
      final existing = await _db
          .from('saved_pharmacies')
          .select('id')
          .eq('user_id', _uid!)
          .eq('pharmacy_id', id)
          .maybeSingle();

      if (existing != null) {
        await _db
            .from('saved_pharmacies')
            .delete()
            .eq('id', existing['id'] as String);
        return false;
      } else {
        await _db.from('saved_pharmacies').insert({
          'user_id':     _uid!,
          'pharmacy_id': id,
        });
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}

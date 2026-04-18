import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/prescription_model.dart';

class PrescriptionProvider extends ChangeNotifier {
  List<PrescriptionModel> _prescriptions = [];
  bool    _isLoading = false;
  String? _error;

  List<PrescriptionModel> get prescriptions => _prescriptions;
  bool    get isLoading => _isLoading;
  String? get error     => _error;

  final _db = SupabaseConstants.client;
  String? get _uid => _db.auth.currentUser?.id;

  Future<void> fetchPrescriptions({String? status}) async {
    if (_uid == null) { _prescriptions = []; notifyListeners(); return; }
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      // Apply filters before order() — order returns a transform builder
      // which doesn't support further filter chaining.
      var filterQuery = _db
          .from('prescriptions')
          .select()
          .eq('c_id', _uid!);

      if (status != null) filterQuery = filterQuery.eq('status', status);

      final raw = await filterQuery.order('uploaded_at', ascending: false);
      _prescriptions = (raw as List)
          .map((row) => PrescriptionModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to load prescriptions.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> uploadPrescription({
    required File imageFile,
    String? doctorName,
    String? doctorLicense,
    String? issueDate,
    String? expiryDate,
    String? notes,
    bool allowAccess = true,
  }) async {
    if (_uid == null) { _error = 'Not logged in.'; notifyListeners(); return false; }
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      // 1. Upload image to Supabase Storage
      final ext      = imageFile.path.split('.').last.toLowerCase();
      final fileName = 'rx_${_uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes    = await imageFile.readAsBytes();

      await _db.storage
          .from('prescriptions')
          .uploadBinary(fileName, bytes,
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));

      final imageUrl = _db.storage.from('prescriptions').getPublicUrl(fileName);

      // 2. Generate prescription number
      final ts = DateTime.now();
      final rxNumber = 'RX-${ts.year}-${ts.millisecondsSinceEpoch.toString().substring(7)}';

      // 3. Insert prescription record
      await _db.from('prescriptions').insert({
        'prescription_number':  rxNumber,
        'c_id':                 _uid,
        'doctor_name':          doctorName?.isNotEmpty == true ? doctorName : null,
        'doctor_license':       doctorLicense?.isNotEmpty == true ? doctorLicense : null,
        'issue_date':           issueDate?.isNotEmpty == true ? issueDate : null,
        'expiry_date':          expiryDate?.isNotEmpty == true ? expiryDate : null,
        'prescription_notes':   notes?.isNotEmpty == true ? notes : null,
        'allow_pharmacy_access': allowAccess,
        'status':               'pending',
        'prescription_image':   imageUrl,
      });

      _isLoading = false;
      notifyListeners();
      await fetchPrescriptions();
      return true;
    } catch (e) {
      _error     = 'Failed to upload prescription.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

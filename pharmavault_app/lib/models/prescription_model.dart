class PrescriptionModel {
  final int prescriptionId;
  final String prescriptionNumber;
  final String? doctorName;
  final String? issueDate;
  final String? expiryDate;
  final String? prescriptionImage;
  final String? prescriptionNotes;
  final String status;
  final bool allowPharmacyAccess;
  final String? uploadedAt;

  PrescriptionModel({
    required this.prescriptionId,
    required this.prescriptionNumber,
    this.doctorName,
    this.issueDate,
    this.expiryDate,
    this.prescriptionImage,
    this.prescriptionNotes,
    required this.status,
    required this.allowPharmacyAccess,
    this.uploadedAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      prescriptionId:      json['prescription_id'] as int,
      prescriptionNumber:  json['prescription_number'] as String,
      doctorName:          json['doctor_name'] as String?,
      issueDate:           json['issue_date'] as String?,
      expiryDate:          json['expiry_date'] as String?,
      prescriptionImage:   json['prescription_image'] as String?,
      prescriptionNotes:   json['prescription_notes'] as String?,
      status:              json['status'] as String? ?? 'pending',
      allowPharmacyAccess: json['allow_pharmacy_access'] == true || json['allow_pharmacy_access'] == 1,
      uploadedAt:          json['uploaded_at'] as String?,
    );
  }
}

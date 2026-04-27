import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/prescription_model.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  const PrescriptionDetailScreen({super.key});

  Color _statusColor(String s) => switch (s) {
    'pending'  => AppColors.warning,
    'verified' => AppColors.success,
    'rejected' => AppColors.error,
    'expired'  => AppColors.textSecondary,
    _          => AppColors.textSecondary,
  };

  IconData _statusIcon(String s) => switch (s) {
    'pending'  => Icons.hourglass_empty_rounded,
    'verified' => Icons.verified_rounded,
    'rejected' => Icons.cancel_outlined,
    'expired'  => Icons.event_busy_outlined,
    _          => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final rx          = ModalRoute.of(context)!.settings.arguments as PrescriptionModel;
    final statusColor = _statusColor(rx.status);
    final cardColor   = Theme.of(context).cardColor;
    final onSurface   = Theme.of(context).colorScheme.onSurface;
    final surfaceHigh = Theme.of(context).colorScheme.surfaceContainerHighest;

    String uploadDate = '';
    try { uploadDate = DateFormat('d MMM yyyy').format(DateTime.parse(rx.uploadedAt ?? '')); } catch (_) {}

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(rx.prescriptionNumber),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy reference number',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: rx.prescriptionNumber));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reference number copied'), duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: statusColor.withAlpha(20), shape: BoxShape.circle),
                    child: Icon(_statusIcon(rx.status), color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (rx.status) {
                            'pending'  => 'Awaiting Verification',
                            'verified' => 'Prescription Verified',
                            'rejected' => 'Prescription Rejected',
                            'expired'  => 'Prescription Expired',
                            _          => rx.status,
                          },
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: statusColor),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          switch (rx.status) {
                            'pending'  => 'Being reviewed by our pharmacy partners.',
                            'verified' => 'You can now order your prescription medicines.',
                            'rejected' => 'Please upload a valid prescription.',
                            'expired'  => 'Please get a new prescription from your doctor.',
                            _          => '',
                          },
                          style: TextStyle(color: onSurface.withAlpha(150), fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Image
            if (rx.prescriptionImage != null && rx.prescriptionImage!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prescription Image',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: onSurface)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: rx.prescriptionImage!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        placeholder: (ctx, url) => Container(
                          height: 200, color: surfaceHigh,
                          child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                        ),
                        errorWidget: (ctx, url, err) => Container(
                          height: 120, color: surfaceHigh,
                          child: Center(child: Icon(Icons.broken_image_outlined, color: onSurface.withAlpha(120), size: 40)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prescription Details',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: onSurface)),
                  const SizedBox(height: 14),
                  _infoRow(context, Icons.tag_rounded, 'Reference', rx.prescriptionNumber),
                  if (uploadDate.isNotEmpty)
                    _infoRow(context, Icons.calendar_today_outlined, 'Uploaded', uploadDate),
                  if (rx.doctorName != null && rx.doctorName!.isNotEmpty)
                    _infoRow(context, Icons.medical_services_outlined, 'Doctor', 'Dr. ${rx.doctorName}'),
                  if (rx.issueDate != null && rx.issueDate!.isNotEmpty)
                    _infoRow(context, Icons.date_range_outlined, 'Issue Date', rx.issueDate!),
                  if (rx.expiryDate != null && rx.expiryDate!.isNotEmpty)
                    _infoRow(context, Icons.event_busy_outlined, 'Expiry Date', rx.expiryDate!),
                  if (rx.prescriptionNotes != null && rx.prescriptionNotes!.isNotEmpty)
                    _infoRow(context, Icons.notes_outlined, 'Notes', rx.prescriptionNotes!),
                  _infoRow(
                    context,
                    rx.allowPharmacyAccess ? Icons.lock_open_outlined : Icons.lock_outlined,
                    'Pharmacy Access',
                    rx.allowPharmacyAccess ? 'Allowed' : 'Restricted',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (rx.status == 'rejected' || rx.status == 'expired')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/upload-prescription'),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload New Prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: onSurface.withAlpha(140)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: onSurface.withAlpha(140), fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

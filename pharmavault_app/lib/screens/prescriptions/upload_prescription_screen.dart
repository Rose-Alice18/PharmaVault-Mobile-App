import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/prescription_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() => _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _doctorCtrl    = TextEditingController();
  final _licenseCtrl   = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _expiryCtrl    = TextEditingController();
  final _notesCtrl     = TextEditingController();
  File?  _imageFile;
  bool   _allowAccess  = true;

  @override
  void dispose() {
    _doctorCtrl.dispose(); _licenseCtrl.dispose();
    _issueDateCtrl.dispose(); _expiryCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (xFile != null && mounted) setState(() => _imageFile = File(xFile.path));
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a prescription image first.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final pp = context.read<PrescriptionProvider>();
    final ok = await pp.uploadPrescription(
      imageFile:     _imageFile!,
      doctorName:    _doctorCtrl.text.trim(),
      doctorLicense: _licenseCtrl.text.trim(),
      issueDate:     _issueDateCtrl.text.trim(),
      expiryDate:    _expiryCtrl.text.trim(),
      notes:         _notesCtrl.text.trim(),
      allowAccess:   _allowAccess,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription uploaded successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pp.error ?? 'Upload failed.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PrescriptionProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Upload Prescription')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── How it works ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How it works', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 14),
                  _HowItWorksStep(number: '1', icon: Icons.upload_file_rounded, title: 'Upload Prescription', subtitle: 'Take a photo or choose from gallery'),
                  const SizedBox(height: 10),
                  _HowItWorksStep(number: '2', icon: Icons.local_pharmacy_rounded, title: 'Pharmacy Reviews', subtitle: 'Our partner pharmacies verify your prescription'),
                  const SizedBox(height: 10),
                  _HowItWorksStep(number: '3', icon: Icons.local_shipping_rounded, title: 'Get Delivered', subtitle: 'Medicines delivered to your doorstep'),
                ],
              ),
            ),

            // ── Image upload area ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Prescription Image', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  // Upload area
                  Container(
                    width: double.infinity,
                    height: _imageFile != null ? 200 : 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _imageFile != null ? AppColors.primary : AppColors.divider,
                        width: _imageFile != null ? 2 : 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                                child: const Icon(Icons.upload_file_rounded, size: 28, color: AppColors.primary),
                              ),
                              const SizedBox(height: 10),
                              const Text('Tap a button below to add your prescription', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 4),
                              const Text('JPEG, PNG • max 5 MB', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  // Camera / Gallery buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded, size: 18),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Form ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doctor Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Text('Optional', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Doctor Name', controller: _doctorCtrl, prefixIcon: Icons.person_outline),
                    const SizedBox(height: 12),
                    AppTextField(label: 'License Number', controller: _licenseCtrl, prefixIcon: Icons.badge_outlined),
                    const SizedBox(height: 20),

                    const Text('Dates', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Text('Optional', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickDate(_issueDateCtrl),
                      child: AbsorbPointer(
                        child: AppTextField(label: 'Issue Date', controller: _issueDateCtrl, prefixIcon: Icons.calendar_today_outlined, hint: 'YYYY-MM-DD'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickDate(_expiryCtrl),
                      child: AbsorbPointer(
                        child: AppTextField(label: 'Expiry Date', controller: _expiryCtrl, prefixIcon: Icons.event_busy_outlined, hint: 'YYYY-MM-DD'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Notes', controller: _notesCtrl, prefixIcon: Icons.notes, maxLines: 3),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _allowAccess,
                      onChanged: (v) => setState(() => _allowAccess = v),
                      title: const Text('Allow pharmacy access', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Pharmacies can view this prescription', style: TextStyle(fontSize: 12)),
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primaryLight,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Important notes ───────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Important: Ensure the prescription is clearly visible and all details are legible. Invalid or tampered prescriptions will be rejected.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Submit button ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: AppButton(label: 'Upload Prescription', onPressed: _submit, isLoading: isLoading, icon: Icons.cloud_upload_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  const _HowItWorksStep({required this.number, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

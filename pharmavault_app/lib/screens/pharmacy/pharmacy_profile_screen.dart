import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showEditProfile() {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditPharmacySheet(
        initialName:    auth.customerName    ?? '',
        initialContact: auth.customerContact ?? '',
        initialCity:    auth.customerCity    ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final name     = auth.customerName    ?? 'Pharmacy';
    final email    = auth.customerEmail   ?? '';
    final city     = auth.customerCity    ?? '';
    final contact  = auth.customerContact ?? '';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20, right: 20, bottom: 28,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Pharmacy Account', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(email, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Info card ───────────────────────────────────────────────────
            _SectionCard(children: [
              _infoTile(Icons.location_city_outlined, 'City', city.isNotEmpty ? city : 'Not set'),
              _divider(),
              _infoTile(Icons.phone_outlined, 'Contact', contact.isNotEmpty ? contact : 'Not set'),
              _divider(),
              _infoTile(Icons.email_outlined, 'Email', email),
            ]),
            const SizedBox(height: 12),

            // ── Actions ─────────────────────────────────────────────────────
            _SectionCard(children: [
              _menuTile(context, Icons.edit_outlined, 'Edit Profile', _showEditProfile),
              _divider(),
              _menuTile(context, Icons.help_outline_rounded, 'Help & Support',
                  () => Navigator.pushNamed(context, '/help-support')),
            ]),
            const SizedBox(height: 12),

            _SectionCard(children: [
              _menuTile(context, Icons.logout_rounded, 'Sign Out', _confirmLogout, color: AppColors.error),
            ]),
            const SizedBox(height: 32),
            Text('PharmaVault v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          ]),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color != null ? color.withAlpha(20) : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: color == null ? const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20) : null,
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.divider);
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }
}

// ── Edit bottom sheet ────────────────────────────────────────────────────────

class _EditPharmacySheet extends StatefulWidget {
  final String initialName;
  final String initialContact;
  final String initialCity;
  const _EditPharmacySheet({required this.initialName, required this.initialContact, required this.initialCity});

  @override
  State<_EditPharmacySheet> createState() => _EditPharmacySheetState();
}

class _EditPharmacySheetState extends State<_EditPharmacySheet> {
  final _formKey     = GlobalKey<FormState>();
  late final _nameCtrl    = TextEditingController(text: widget.initialName);
  late final _contactCtrl = TextEditingController(text: widget.initialContact);
  late final _cityCtrl    = TextEditingController(text: widget.initialCity);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.updateProfile(
      name:    _nameCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      city:    _cityCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile updated' : (auth.error ?? 'Update failed')),
        backgroundColor: ok ? AppColors.primary : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              const Text('Edit Pharmacy Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Pharmacy Name',
                controller: _nameCtrl,
                prefixIcon: Icons.store_outlined,
                inputFormatters: AppFormatters.name,
                validator: AppValidators.name,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Phone Number',
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                inputFormatters: AppFormatters.phone,
                validator: AppValidators.phone,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'City',
                controller: _cityCtrl,
                prefixIcon: Icons.location_city_outlined,
                inputFormatters: AppFormatters.city,
                validator: AppValidators.city,
              ),
              const SizedBox(height: 24),
              AppButton(label: 'Save Changes', onPressed: _save, isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }
}

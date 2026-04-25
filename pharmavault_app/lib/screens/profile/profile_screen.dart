import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      context.read<OrderProvider>().fetchOrders();
      context.read<PrescriptionProvider>().fetchPrescriptions();
    }
  }

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

  Future<void> _onChangePhoto() async {
    final auth = context.read<AuthProvider>();
    final ok   = await auth.uploadProfilePhoto();
    if (!mounted) return;
    if (!ok && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  void _showEditProfile() {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(
        initialName:    auth.customerName    ?? '',
        initialContact: auth.customerContact ?? '',
        initialCity:    auth.customerCity    ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final orders   = context.watch<OrderProvider>().orders;
    final rxCount  = context.watch<PrescriptionProvider>().prescriptions.length;
    final name     = auth.customerName ?? 'User';
    final email    = auth.customerEmail ?? '';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    final imageUrl = auth.customerImage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20, right: 20, bottom: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Tappable avatar
                  GestureDetector(
                    onTap: auth.isLoading ? null : _onChangePhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: imageUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    width: 80, height: 80,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Text(initials,
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 24, height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        )
                                      : Text(initials,
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                ),
                        ),
                        // Camera badge
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(email, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      _StatBox(label: 'Orders', value: '${orders.length}'),
                      _vDivider(),
                      _StatBox(label: 'Prescriptions', value: '$rxCount'),
                      _vDivider(),
                      const _StatBox(label: 'Addresses', value: '1'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Account section ──────────────────────────────────────────────
            _SectionCard(
              children: [
                _menuTile(context, Icons.person_outline_rounded, 'Edit Profile', _showEditProfile),
                _divider(),
                _menuTile(context, Icons.receipt_long_rounded, 'My Orders', () => Navigator.pushNamed(context, '/main')),
                _divider(),
                _menuTile(context, Icons.description_rounded, 'My Prescriptions', () => Navigator.pushNamed(context, '/prescriptions')),
                _divider(),
                _menuTile(context, Icons.location_on_rounded, 'Saved Addresses', () => Navigator.pushNamed(context, '/saved-addresses')),
                _divider(),
                _menuTile(context, Icons.local_pharmacy_rounded, 'Saved Pharmacies', () => Navigator.pushNamed(context, '/saved-pharmacies')),
              ],
            ),
            const SizedBox(height: 12),

            // ── Preferences section ──────────────────────────────────────────
            _SectionCard(
              children: [
                _menuTile(context, Icons.notifications_rounded, 'Notifications', () => Navigator.pushNamed(context, '/notifications')),
                _divider(),
                _menuTile(context, Icons.settings_rounded, 'Settings', () => Navigator.pushNamed(context, '/settings')),
                _divider(),
                _menuTile(context, Icons.help_rounded, 'Help & Support', () => Navigator.pushNamed(context, '/help-support')),
              ],
            ),
            const SizedBox(height: 12),

            // ── Sign out ─────────────────────────────────────────────────────
            _SectionCard(
              children: [
                _menuTile(context, Icons.logout_rounded, 'Sign Out', _confirmLogout, color: AppColors.error),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              'PharmaVault v1.0.0',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white.withAlpha(50));

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

// ── Edit Profile Bottom Sheet ────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initialContact;
  final String initialCity;

  const _EditProfileSheet({
    required this.initialName,
    required this.initialContact,
    required this.initialCity,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
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
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.primary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Update failed'), backgroundColor: AppColors.error),
      );
    }
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
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline_rounded,
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

// ── Shared widgets ───────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(200))),
        ],
      ),
    );
  }
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

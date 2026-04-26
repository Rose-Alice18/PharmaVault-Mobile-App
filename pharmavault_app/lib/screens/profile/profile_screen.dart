import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/ghana_cities.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../providers/theme_provider.dart';
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
  int _addressCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      context.read<OrderProvider>().fetchOrders();
      context.read<PrescriptionProvider>().fetchPrescriptions();
      _loadAddressCount();
    }
  }

  Future<void> _loadAddressCount() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final data = await Supabase.instance.client
          .from('user_addresses')
          .select('id')
          .eq('user_id', uid);
      if (!mounted) return;
      setState(() => _addressCount = (data as List).length);
    } catch (_) {}
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
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
    final ok = await auth.uploadProfilePhoto();
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
        initialName: auth.customerName ?? '',
        initialContact: auth.customerContact ?? '',
        initialCity: auth.customerCity ?? '',
      ),
    );
  }

  void _showChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>().orders;
    final rxCount = context.watch<PrescriptionProvider>().prescriptions.length;
    final name = auth.customerName ?? 'User';
    final email = auth.customerEmail ?? '';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    final imageUrl = auth.customerImage;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Tappable avatar
                  GestureDetector(
                    onTap: auth.isLoading ? null : _onChangePhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: imageUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                  ),
                                )
                              : Center(
                                  child: auth.isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        )
                                      : Text(
                                          initials,
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                ),
                        ),
                        // Camera badge
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      _StatBox(label: 'Orders', value: '${orders.length}'),
                      _vDivider(),
                      _StatBox(label: 'Prescriptions', value: '$rxCount'),
                      _vDivider(),
                      _StatBox(label: 'Addresses', value: '$_addressCount'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Account section ──────────────────────────────────────────────
            _SectionCard(
              children: [
                _menuTile(
                  context,
                  Icons.person_outline_rounded,
                  'Edit Profile',
                  _showEditProfile,
                ),
                _divider(),
                _menuTile(
                  context,
                  Icons.lock_outline_rounded,
                  'Change Password',
                  _showChangePassword,
                ),
                _divider(),
                _menuTile(
                  context,
                  Icons.receipt_long_rounded,
                  'My Orders',
                  () => Navigator.pushNamed(context, '/main'),
                ),
                _divider(),
                _menuTile(
                  context,
                  Icons.description_rounded,
                  'My Prescriptions',
                  () => Navigator.pushNamed(context, '/prescriptions'),
                ),
                _divider(),
                _menuTile(
                  context,
                  Icons.location_on_rounded,
                  'Saved Addresses',
                  () => Navigator.pushNamed(context, '/saved-addresses'),
                ),
                _divider(),
                _menuTile(
                  context,
                  Icons.local_pharmacy_rounded,
                  'Saved Pharmacies',
                  () => Navigator.pushNamed(context, '/saved-pharmacies'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Preferences section ──────────────────────────────────────────
            _SectionCard(
              children: [
                _menuTile(
                  context,
                  Icons.notifications_rounded,
                  'Notifications',
                  () => Navigator.pushNamed(context, '/notifications'),
                ),
                _divider(),
                _darkModeTile(context),
                _divider(),
                _menuTile(
                  context,
                  Icons.settings_rounded,
                  'Settings',
                  () => Navigator.pushNamed(context, '/settings'),
                ),
                _divider(),
                _menuTile(
                  context,
                  Icons.help_rounded,
                  'Help & Support',
                  () => Navigator.pushNamed(context, '/help-support'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Sign out ─────────────────────────────────────────────────────
            if (auth.userId == '45c383e3-484d-4e9f-b95d-6f77cb831497') ...[
              const SizedBox(height: 16),
              _SectionCard(
                children: [
                  _menuTile(
                    context,
                    Icons.admin_panel_settings_rounded,
                    'Admin Panel',
                    () => Navigator.pushNamed(context, '/admin-panel'),
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                _menuTile(
                  context,
                  Icons.logout_rounded,
                  'Sign Out',
                  _confirmLogout,
                  color: AppColors.error,
                ),
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

  Widget _vDivider() => Container(
    width: 1,
    height: 36,
    color: Theme.of(context).dividerColor.withAlpha(80),
  );

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final adaptive = color ?? Theme.of(context).colorScheme.onSurface;
    final bgColor = color != null
        ? color.withAlpha(20)
        : AppColors.primary.withAlpha(22);
    final iconColor = color ?? AppColors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: adaptive,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: color == null
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _divider() => Divider(
    height: 1,
    indent: 56,
    endIndent: 16,
    color: Theme.of(context).dividerColor,
  );

  Widget _darkModeTile(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(22),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        'Dark Mode',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: isDark,
        onChanged: (_) => context.read<ThemeProvider>().toggle(),
        activeColor: theme.colorScheme.primary,
        activeTrackColor: theme.colorScheme.primary.withOpacity(0.35),
      ),
    );
  }
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
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.initialName);
  late final _contactCtrl = TextEditingController(text: widget.initialContact);
  late String? _selectedCity;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCity.trim();
    _selectedCity = kGhanaCities.contains(initial) ? initial : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      city: _selectedCity ?? '',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profile',
                style:
                    theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ) ??
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
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
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(
                    Icons.location_city_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  filled: true,
                  fillColor:
                      theme.inputDecorationTheme.fillColor ??
                      (theme.brightness == Brightness.dark
                          ? const Color(0xFF1F2937)
                          : Colors.white),
                  labelStyle:
                      theme.inputDecorationTheme.labelStyle ??
                      TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items: kGhanaCities
                    .map(
                      (city) => DropdownMenuItem(
                        value: city,
                        child: Text(
                          city,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCity = v),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please select your city.'
                    : null,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Changes',
                onPressed: _save,
                isLoading: isLoading,
              ),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(200)),
          ),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }
}

// ── Change Password Bottom Sheet ─────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(_newPassCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to update password'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a strong password with at least 8 characters.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'New Password',
                controller: _newPassCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                inputFormatters: AppFormatters.password,
                validator: AppValidators.password,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Confirm New Password',
                controller: _confirmCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                inputFormatters: AppFormatters.password,
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Please confirm your password.';
                  if (v != _newPassCtrl.text) return 'Passwords do not match.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Update Password',
                onPressed: _save,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

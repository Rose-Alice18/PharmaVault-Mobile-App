import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/ghana_cities.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

enum _PasswordStrength { none, weak, fair, good, strong }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _contactCtrl     = TextEditingController();
  final _licenseCtrl     = TextEditingController();

  bool _isPharmacy    = false;
  bool _submitted     = false;
  String? _confirmError;
  String? _selectedCity;
  _PasswordStrength _strength = _PasswordStrength.none;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _contactCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  _PasswordStrength _getStrength(String pw) {
    if (pw.isEmpty) return _PasswordStrength.none;
    final hasUpper   = pw.contains(RegExp(r'[A-Z]'));
    final hasLower   = pw.contains(RegExp(r'[a-z]'));
    final hasDigit   = pw.contains(RegExp(r'[0-9]'));
    final hasSpecial = pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final long       = pw.length >= 10;
    final score      = [hasUpper, hasLower, hasDigit, hasSpecial, long].where((b) => b).length;
    if (pw.length < 6) return _PasswordStrength.weak;
    if (score <= 2)    return _PasswordStrength.fair;
    if (score == 3)    return _PasswordStrength.good;
    return _PasswordStrength.strong;
  }

  void _checkConfirmMatch() {
    final confirm  = _confirmPassCtrl.text;
    final password = _passCtrl.text;
    if (confirm.isEmpty) { setState(() => _confirmError = null); return; }
    if (password.startsWith(confirm)) { setState(() => _confirmError = null); return; }
    setState(() => _confirmError = 'Passwords do not match');
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _confirmError = 'Passwords do not match');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
      name:                    _nameCtrl.text.trim(),
      email:                   _emailCtrl.text.trim().toLowerCase(),
      password:                _passCtrl.text,
      contact:                 _contactCtrl.text.trim(),
      country:                 'Ghana',
      city:                    _selectedCity ?? '',
      isPharmacyRegistration:  _isPharmacy,
      licenseNumber:           _isPharmacy ? _licenseCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (ok) {
      if (_isPharmacy) {
        Navigator.pushReplacementNamed(context, '/pharmacy-pending');
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Account',
            style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Account type toggle ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _TypeTab(
                        label: 'Customer',
                        icon: Icons.person_rounded,
                        selected: !_isPharmacy,
                        onTap: () => setState(() { _isPharmacy = false; _submitted = false; }),
                      ),
                      _TypeTab(
                        label: 'Pharmacy',
                        icon: Icons.local_pharmacy_rounded,
                        selected: _isPharmacy,
                        onTap: () => setState(() { _isPharmacy = true; _submitted = false; }),
                      ),
                    ],
                  ),
                ),

                if (_isPharmacy) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withAlpha(60)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pharmacy accounts require verification by our admin team before you can access the pharmacy dashboard.',
                            style: TextStyle(fontSize: 12, color: AppColors.warning, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Fields ──────────────────────────────────────────────────
                AppTextField(
                  label: _isPharmacy ? 'Pharmacy Name' : 'Full Name',
                  controller: _nameCtrl,
                  prefixIcon: _isPharmacy ? Icons.local_pharmacy_outlined : Icons.person_outline,
                  inputFormatters: AppFormatters.name,
                  validator: AppValidators.name,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Email Address',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  inputFormatters: AppFormatters.email,
                  validator: AppValidators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Password',
                  controller: _passCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  inputFormatters: AppFormatters.password,
                  validator: AppValidators.password,
                  onChanged: (v) => setState(() => _strength = _getStrength(v)),
                ),
                if (_strength != _PasswordStrength.none) ...[
                  const SizedBox(height: 8),
                  _StrengthMeter(strength: _strength),
                ],
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Confirm Password',
                  controller: _confirmPassCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  inputFormatters: AppFormatters.password,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password.';
                    if (v != _passCtrl.text) return 'Passwords do not match.';
                    return null;
                  },
                  onChanged: (_) => _checkConfirmMatch(),
                ),
                if (_confirmError != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(_confirmError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                ],
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

                if (_isPharmacy) ...[
                  AppTextField(
                    label: 'License / Registration Number',
                    controller: _licenseCtrl,
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'License number is required.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  // Country — hardcoded to Ghana
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.public, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        const Text('Ghana',
                            style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                        const Spacer(),
                        const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // City dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  decoration: InputDecoration(
                    labelText: _isPharmacy ? 'Pharmacy Location / City' : 'City',
                    prefixIcon: const Icon(Icons.location_city_outlined,
                        color: AppColors.textSecondary, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error)),
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: kGhanaCities
                      .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Please select your city.' : null,
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: _isPharmacy ? 'Submit for Verification' : 'Create Account',
                  onPressed: _submit,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Sign In',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6)]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17,
                  color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  final _PasswordStrength strength;
  const _StrengthMeter({required this.strength});

  @override
  Widget build(BuildContext context) {
    final (label, color, filled) = switch (strength) {
      _PasswordStrength.weak   => ('Weak',   AppColors.error,         1),
      _PasswordStrength.fair   => ('Fair',   AppColors.warning,       2),
      _PasswordStrength.good   => ('Good',   const Color(0xFF0891B2), 3),
      _PasswordStrength.strong => ('Strong', AppColors.success,       4),
      _                        => ('',       Colors.transparent,      0),
    };
    return Row(
      children: [
        ...List.generate(4, (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: i < filled ? color : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

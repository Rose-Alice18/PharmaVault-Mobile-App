import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _submitted  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(
      _emailCtrl.text.trim().toLowerCase(),
      _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      context.read<NotificationProvider>().subscribe(auth.userId!);
      if (auth.isPendingPharmacy) {
        Navigator.pushReplacementNamed(context, '/pharmacy-pending');
      } else if (auth.isPharmacy) {
        Navigator.pushReplacementNamed(context, '/pharmacy-main');
      } else {
        context.read<CartProvider>().fetchCart();
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed.'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<AuthProvider>();
    final ok   = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.read<NotificationProvider>().subscribe(auth.userId!);
      if (auth.isPendingPharmacy) {
        Navigator.pushReplacementNamed(context, '/pharmacy-pending');
      } else if (auth.isPharmacy) {
        Navigator.pushReplacementNamed(context, '/pharmacy-main');
      } else {
        context.read<CartProvider>().fetchCart();
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.local_pharmacy, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Welcome back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Sign in to your PharmaVault account',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 36),
                AppTextField(
                  label: 'Email address',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  inputFormatters: AppFormatters.email,
                  validator: AppValidators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  inputFormatters: AppFormatters.password,
                  validator: (v) => (v == null || v.isEmpty) ? 'Password is required.' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Sign In', onPressed: _submit, isLoading: isLoading),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: isLoading ? null : _googleSignIn,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleIcon(),
                        SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: const Text('Register',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: RichText(
          text: const TextSpan(
            text: 'G',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4285F4),
              fontFamily: 'Arial',
            ),
          ),
        ),
      ),
    );
  }
}

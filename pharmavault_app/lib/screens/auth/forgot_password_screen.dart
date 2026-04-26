import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _submitted  = false;
  bool _sent       = false;
  String _sentTo   = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim().toLowerCase();
    final auth  = context.read<AuthProvider>();
    final ok    = await auth.forgotPassword(email);
    if (!mounted) return;
    if (ok) {
      setState(() { _sent = true; _sentTo = email; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Something went wrong. Please try again.'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _sent ? _buildSuccess() : _buildForm(isLoading),
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded, size: 36, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Reset your password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Enter the email address on your account and we\'ll send you a reset link.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email address',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            inputFormatters: AppFormatters.email,
            validator: AppValidators.email,
          ),
          const SizedBox(height: 28),
          AppButton(label: 'Send Reset Link', onPressed: _submit, isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded, size: 40, color: AppColors.success),
        ),
        const SizedBox(height: 28),
        const Text('Check your inbox',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            children: [
              const TextSpan(text: 'We sent a password reset link to\n'),
              TextSpan(
                text: _sentTo,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Didn't receive it? Check your spam folder.",
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

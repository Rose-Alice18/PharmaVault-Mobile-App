import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class PharmacyPendingScreen extends StatefulWidget {
  const PharmacyPendingScreen({super.key});

  @override
  State<PharmacyPendingScreen> createState() => _PharmacyPendingScreenState();
}

class _PharmacyPendingScreenState extends State<PharmacyPendingScreen> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    final auth = context.read<AuthProvider>();
    await auth.initialize();
    if (!mounted) return;
    setState(() => _checking = false);
    if (auth.isPharmacy) {
      Navigator.pushReplacementNamed(context, '/pharmacy-main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still under review. We\'ll notify you when approved.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 48, color: AppColors.warning),
              ),
              const SizedBox(height: 28),
              const Text(
                'Verification Pending',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your pharmacy account is under review by our admin team. This usually takes 1–2 business days.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('mailto:roselinetsatsu@gmail.com')),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    children: [
                      TextSpan(text: 'Questions? Contact '),
                      TextSpan(
                        text: 'PharmaVault Support',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (auth.customerName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_pharmacy_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(auth.customerName!,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checking ? null : _checkStatus,
                  icon: _checking
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(_checking ? 'Checking...' : 'Check Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

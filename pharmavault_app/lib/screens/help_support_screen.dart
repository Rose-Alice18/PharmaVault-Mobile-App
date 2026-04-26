import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaq;

  static const _faqs = [
    _FaqData(
      'How do I place an order?',
      'Browse medicines in the Home or Search tab, add items to your cart, then proceed to checkout. Fill in your delivery address and confirm your order.',
    ),
    _FaqData(
      'How long does delivery take?',
      'Delivery typically takes 1–3 hours within Accra. Times may vary depending on your location and pharmacy availability.',
    ),
    _FaqData(
      'Can I upload a prescription?',
      'Yes! Tap "Upload Prescription" on the home screen or go to Profile → My Prescriptions. Our partner pharmacies will review and fulfil your request.',
    ),
    _FaqData(
      'How do I cancel an order?',
      'You can cancel a pending order from the Orders tab. Tap the order and select Cancel. Orders already being processed cannot be cancelled.',
    ),
    _FaqData(
      'What payment methods are accepted?',
      'We accept card payments (Visa / Mastercard via Paystack), Mobile Money (MTN MoMo, Vodafone Cash, AirtelTigo), and cash on delivery.',
    ),
    _FaqData(
      'How do I track my order?',
      'Go to the Orders tab to view your active orders and their live status — Pending, Processing, Out for Delivery, or Delivered.',
    ),
    _FaqData(
      'How do I save a pharmacy?',
      'Open any pharmacy page and tap the bookmark icon. Saved pharmacies appear under Profile → Saved Pharmacies.',
    ),
  ];

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open — please try manually.')),
        );
      }
    }
  }

  void _showLiveChatComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live chat coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ───────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0D7A3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'We\'re here to help',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Our support team is available\nMon – Sat, 8 AM – 8 PM',
                          style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),

            // ── Contact options ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _ContactCard(
                    icon: Icons.phone_rounded,
                    label: 'Call Us',
                    sub: '0591 765 158',
                    color: const Color(0xFF0284C7),
                    onTap: () => _launch(Uri.parse('tel:0591765158')),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ContactCard(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    sub: 'support@\npharmavault',
                    color: const Color(0xFF7C3AED),
                    onTap: () => _launch(Uri.parse('mailto:roselinetsatsu@gmail.com?subject=PharmaVault Support')),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ContactCard(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Live Chat',
                    sub: 'Coming\nsoon',
                    color: AppColors.primary,
                    onTap: _showLiveChatComingSoon,
                  )),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Response time banner ─────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Average response time: under 2 hours on working days.',
                      style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── FAQ ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
              ),
              child: Column(
                children: List.generate(_faqs.length, (i) {
                  final faq = _faqs[i];
                  final isExpanded = _expandedFaq == i;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(i == 0
                        ? 16
                        : i == _faqs.length - 1
                            ? 16
                            : 0),
                    child: Column(
                      children: [
                        if (i > 0)
                          Divider(
                            height: 1, indent: 16, endIndent: 16,
                            color: Theme.of(context).dividerColor,
                          ),
                        InkWell(
                          onTap: () => setState(() => _expandedFaq = isExpanded ? null : i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12, top: 1),
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: isExpanded ? AppColors.primary : (isDark ? const Color(0xFF4B5563) : AppColors.divider),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    faq.question,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isExpanded
                                          ? AppColors.primary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: isExpanded ? AppColors.primary : Theme.of(context).colorScheme.onSurface.withAlpha(120),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.fromLTRB(34, 0, 16, 16),
                            child: Text(
                              faq.answer,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // ── Footer ────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    'PharmaVault • Your Digital Pharmacy Companion',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0 — Built for Ghana 🇬🇭',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqData {
  final String question;
  final String answer;
  const _FaqData(this.question, this.answer);
}

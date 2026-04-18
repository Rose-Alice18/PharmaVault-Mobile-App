import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaq;

  static const _faqs = [
    _FaqData('How do I place an order?', 'Browse medicines in the Home or Search tab, add items to your cart, then proceed to checkout. Fill in your delivery details and confirm your order.'),
    _FaqData('How long does delivery take?', 'Delivery typically takes 1–3 hours within Accra. Delivery times may vary depending on your location and pharmacy availability.'),
    _FaqData('Can I upload a prescription?', 'Yes! Tap the "Upload Prescription" banner on the home screen or go to Profile → My Prescriptions to upload your doctor\'s prescription.'),
    _FaqData('How do I cancel an order?', 'You can cancel a pending order from the Orders tab. Tap your order and select Cancel. Orders that are already being processed cannot be cancelled.'),
    _FaqData('What payment methods are accepted?', 'We accept Mobile Money (MTN MoMo, Vodafone Cash, AirtelTigo) and cash on delivery.'),
    _FaqData('How do I track my order?', 'Go to the Orders tab to view your active orders and their current status in real time.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contact us ────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Contact Us', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _ContactCard(icon: Icons.chat_rounded, label: 'Live Chat', sub: 'Chat with us', color: AppColors.primary, onTap: () {})),
                  const SizedBox(width: 10),
                  Expanded(child: _ContactCard(icon: Icons.phone_rounded, label: 'Call Us', sub: '+233 XX XXX XXXX', color: const Color(0xFF0284C7), onTap: () {})),
                  const SizedBox(width: 10),
                  Expanded(child: _ContactCard(icon: Icons.email_rounded, label: 'Email', sub: 'support@pharmavault', color: const Color(0xFF7C3AED), onTap: () {})),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── FAQ ───────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Frequently Asked Questions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
              ),
              child: Column(
                children: List.generate(_faqs.length, (i) {
                  final faq = _faqs[i];
                  final isExpanded = _expandedFaq == i;
                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
                      InkWell(
                        onTap: () => setState(() => _expandedFaq = isExpanded ? null : i),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(faq.question,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isExpanded ? AppColors.primary : AppColors.textPrimary)),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary, size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Text(faq.answer, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
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
  const _ContactCard({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
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

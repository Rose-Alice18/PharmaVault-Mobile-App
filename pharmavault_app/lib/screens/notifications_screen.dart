import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _notifications = [
    _NotifData(
      icon: Icons.local_shipping_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      title: 'Order On the Way',
      body: 'Your order INV-2024-001 is out for delivery.',
      time: '2 min ago',
      isNew: true,
    ),
    _NotifData(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      iconBg: Color(0xFFDCFCE7),
      title: 'Order Delivered',
      body: 'Your order INV-2024-002 has been delivered successfully.',
      time: '1 hr ago',
      isNew: true,
    ),
    _NotifData(
      icon: Icons.local_pharmacy_rounded,
      iconColor: Color(0xFF7C3AED),
      iconBg: Color(0xFFF3E8FF),
      title: 'Prescription Approved',
      body: 'Your prescription has been approved by MedPlus Pharmacy.',
      time: '3 hrs ago',
      isNew: false,
    ),
    _NotifData(
      icon: Icons.local_offer_rounded,
      iconColor: Color(0xFFD97706),
      iconBg: Color(0xFFFEF3C7),
      title: '20% Off on Vitamins',
      body: 'Get 20% off on all vitamin supplements this weekend only!',
      time: 'Yesterday',
      isNew: false,
    ),
    _NotifData(
      icon: Icons.medical_services_rounded,
      iconColor: Color(0xFF0284C7),
      iconBg: Color(0xFFE0F2FE),
      title: 'New Product Available',
      body: 'Paracetamol 500mg is now back in stock at partner pharmacies.',
      time: '2 days ago',
      isNew: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final n = _notifications[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.isNew ? AppColors.primaryLight.withAlpha(80) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: n.isNew ? Border.all(color: AppColors.primaryLight, width: 1.5) : null,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: n.iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(n.icon, color: n.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                          ),
                          if (n.isNew)
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(n.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 6),
                      Text(n.time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotifData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final String time;
  final bool isNew;
  const _NotifData({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, required this.body, required this.time, required this.isNew,
  });
}

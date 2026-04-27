import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    return switch (type) {
      'order'        => Icons.local_shipping_rounded,
      'prescription' => Icons.local_pharmacy_rounded,
      _              => Icons.notifications_rounded,
    };
  }

  Color _iconColor(String type) {
    return switch (type) {
      'order'        => AppColors.primary,
      'prescription' => const Color(0xFF7C3AED),
      _              => AppColors.secondary,
    };
  }

  String _timeLabel(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)    return '${diff.inHours} hr ago';
    if (diff.inDays == 1)     return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final items         = notifProvider.items;
    final onSurface     = Theme.of(context).colorScheme.onSurface;
    final cardColor     = Theme.of(context).cardColor;
    final isDark        = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: cardColor,
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton(
              onPressed: notifProvider.markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.notifications_off_outlined, size: 40, color: onSurface.withAlpha(120)),
                  ),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: onSurface)),
                  const SizedBox(height: 4),
                  Text('Order updates will appear here',
                      style: TextStyle(color: onSurface.withAlpha(150), fontSize: 13)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                final unreadBg = isDark
                    ? AppColors.primary.withAlpha(30)
                    : AppColors.primaryLight.withAlpha(60);
                final unreadBorder = isDark
                    ? AppColors.primary.withAlpha(80)
                    : AppColors.primaryLight;
                final readBorder = Theme.of(context).dividerColor;

                return GestureDetector(
                  onTap: () {
                    n.isRead = true;
                    notifProvider.markAllRead();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead ? cardColor : unreadBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: n.isRead ? readBorder : unreadBorder,
                        width: 1.5,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6)],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _iconColor(n.type).withAlpha(isDark ? 30 : 20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_iconForType(n.type), color: _iconColor(n.type), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(n.title,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: onSurface)),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(n.body,
                                  style: TextStyle(fontSize: 13, color: onSurface.withAlpha(160), height: 1.4)),
                              const SizedBox(height: 6),
                              Text(_timeLabel(n.time),
                                  style: TextStyle(fontSize: 11, color: onSurface.withAlpha(120))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

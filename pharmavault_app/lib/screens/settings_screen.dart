import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _orderUpdates      = true;
  bool _promotions        = false;
  bool _locationAccess    = true;
  bool _loaded            = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('notif_push')      ?? true;
      _orderUpdates      = prefs.getBool('notif_orders')    ?? true;
      _promotions        = prefs.getBool('notif_promo')     ?? false;
      _locationAccess    = prefs.getBool('privacy_location') ?? true;
      _loaded            = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _sectionLabel('Notifications'),
            _SectionCard(children: [
              _switchTile(
                icon: Icons.notifications_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications',
                value: _pushNotifications,
                onChanged: (v) { setState(() => _pushNotifications = v); _save('notif_push', v); },
              ),
              _divider(),
              _switchTile(
                icon: Icons.receipt_long_rounded,
                title: 'Order Updates',
                subtitle: 'Order status and delivery updates',
                value: _orderUpdates,
                onChanged: (v) { setState(() => _orderUpdates = v); _save('notif_orders', v); },
              ),
              _divider(),
              _switchTile(
                icon: Icons.local_offer_rounded,
                title: 'Promotions',
                subtitle: 'Deals, discounts and offers',
                value: _promotions,
                onChanged: (v) { setState(() => _promotions = v); _save('notif_promo', v); },
              ),
            ]),
            const SizedBox(height: 16),
            _sectionLabel('Privacy'),
            _SectionCard(children: [
              _switchTile(
                icon: Icons.location_on_rounded,
                title: 'Location Access',
                subtitle: 'Used to find nearby pharmacies',
                value: _locationAccess,
                onChanged: (v) { setState(() => _locationAccess = v); _save('privacy_location', v); },
              ),
            ]),
            const SizedBox(height: 16),
            _sectionLabel('App'),
            _SectionCard(children: [
              _navTile(context, icon: Icons.language_rounded,   title: 'Language',            trailing: 'English'),
              _divider(),
              _navTile(context, icon: Icons.info_rounded,       title: 'About PharmaVault',   trailing: 'v1.0.0'),
              _divider(),
              _navTile(context, icon: Icons.privacy_tip_rounded, title: 'Privacy Policy'),
              _divider(),
              _navTile(context, icon: Icons.description_rounded, title: 'Terms of Service'),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
  );

  Widget _switchTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary, activeTrackColor: AppColors.primaryLight),
    );
  }

  Widget _navTile(BuildContext context, {required IconData icon, required String title, String? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.divider);
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

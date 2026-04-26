import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _db = SupabaseConstants.client;
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _fetchError = null; });
    try {
      final data = await _db
          .from('profiles')
          .select('id, customer_name, customer_email, customer_contact, customer_city, license_number, created_at')
          .eq('customer_type', 'pharmacy_pending')
          .order('created_at', ascending: false);
      if (mounted) setState(() => _pending = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) setState(() => _fetchError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> pharmacy) async {
    final confirmed = await _confirm(
      context,
      title: 'Approve Pharmacy',
      message: 'Approve "${pharmacy['customer_name']}"? They will get full pharmacy dashboard access.',
      confirmLabel: 'Approve',
      confirmColor: AppColors.success,
    );
    if (!confirmed) return;
    await _db.from('profiles').update({'customer_type': 'pharmacy'}).eq('id', pharmacy['id']);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pharmacy approved successfully'),
        backgroundColor: AppColors.success,
      ));
      setState(() => _pending.removeWhere((p) => p['id'] == pharmacy['id']));
    }
  }

  Future<void> _reject(Map<String, dynamic> pharmacy) async {
    final confirmed = await _confirm(
      context,
      title: 'Reject Pharmacy',
      message: 'Reject "${pharmacy['customer_name']}"? Their account will be marked as rejected.',
      confirmLabel: 'Reject',
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;
    await _db.from('profiles').update({'customer_type': 'pharmacy_rejected'}).eq('id', pharmacy['id']);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pharmacy rejected'),
        backgroundColor: AppColors.error,
      ));
      setState(() => _pending.removeWhere((p) => p['id'] == pharmacy['id']));
    }
  }

  Future<bool> _confirm(BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: TextStyle(color: confirmColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Admin Panel'),
            if (_pending.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                child: Text('${_pending.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetch),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _fetchError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.warning),
                        const SizedBox(height: 12),
                        const Text('Access Restricted',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        const Text(
                          'Add this RLS policy in Supabase → Table Editor → profiles → Policies:',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const SelectableText(
                            'CREATE POLICY "superadmin_read_all"\nON public.profiles FOR SELECT\nTO authenticated\nUSING (\n  auth.uid() = id OR\n  auth.uid() = \'45c383e3-484d-4e9f-b95d-6f77cb831497\'::uuid\n);',
                            style: TextStyle(fontSize: 11, color: Color(0xFF86EFAC), fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetch,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
          : _pending.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 56, color: AppColors.success),
                      SizedBox(height: 12),
                      Text('No pending applications',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('All pharmacy applications have been reviewed',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pending.length,
                    itemBuilder: (context, i) {
                      final p           = _pending[i];
                      final name        = p['customer_name'] as String? ?? 'Unknown';
                      final email       = p['customer_email'] as String? ?? '';
                      final contact     = p['customer_contact'] as String? ?? '';
                      final city        = p['customer_city'] as String? ?? '';
                      final license     = p['license_number'] as String? ?? 'Not provided';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning.withAlpha(60), width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.warning, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withAlpha(20),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('Pending Verification',
                                            style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppColors.divider),
                            const SizedBox(height: 12),
                            _infoRow(Icons.email_outlined, 'Email', email),
                            _infoRow(Icons.phone_outlined, 'Phone', contact.isNotEmpty ? contact : 'N/A'),
                            _infoRow(Icons.location_city_outlined, 'City', city.isNotEmpty ? city : 'N/A'),
                            _infoRow(Icons.badge_outlined, 'License No.', license),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _reject(p),
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(color: AppColors.error),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approve(p),
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

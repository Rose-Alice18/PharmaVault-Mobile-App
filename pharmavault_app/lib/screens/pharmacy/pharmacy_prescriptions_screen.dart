import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';

class PharmacyPrescriptionsScreen extends StatefulWidget {
  const PharmacyPrescriptionsScreen({super.key});

  @override
  State<PharmacyPrescriptionsScreen> createState() => _PharmacyPrescriptionsScreenState();
}

class _PharmacyPrescriptionsScreenState extends State<PharmacyPrescriptionsScreen> {
  final _db = SupabaseConstants.client;
  List<Map<String, dynamic>> _all      = [];
  List<Map<String, dynamic>> _filtered = [];
  bool    _loading      = true;
  String? _error;
  String  _statusFilter = 'all';

  static const _filterStatuses = ['all', 'pending', 'verified', 'rejected', 'expired'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _db
          .from('prescriptions')
          .select('*, profiles(customer_name, customer_contact)')
          .eq('allow_pharmacy_access', true)
          .order('uploaded_at', ascending: false);
      setState(() {
        _all = List<Map<String, dynamic>>.from(data as List);
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load prescriptions.'; _loading = false; });
    }
  }

  void _applyFilter() {
    _filtered = _statusFilter == 'all'
        ? List.from(_all)
        : _all.where((p) => p['status'] == _statusFilter).toList();
  }

  Future<void> _updateStatus(int rxId, String newStatus) async {
    try {
      await _db.from('prescriptions').update({'status': newStatus}).eq('prescription_id', rxId);
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Prescription marked as $newStatus'),
          backgroundColor: newStatus == 'verified' ? AppColors.success : AppColors.error,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showDetail(Map<String, dynamic> rx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PrescriptionDetailSheet(
        rx: rx,
        onUpdateStatus: (status) {
          Navigator.pop(ctx);
          _updateStatus(rx['prescription_id'] as int, status);
        },
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'pending'  => AppColors.warning,
    'verified' => AppColors.success,
    'rejected' => AppColors.error,
    'expired'  => AppColors.textSecondary,
    _          => AppColors.textSecondary,
  };

  IconData _statusIcon(String s) => switch (s) {
    'pending'  => Icons.hourglass_empty_rounded,
    'verified' => Icons.verified_rounded,
    'rejected' => Icons.cancel_outlined,
    'expired'  => Icons.event_busy_outlined,
    _          => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final pending = _all.where((p) => p['status'] == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Prescriptions'),
            if (pending > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetch),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filterStatuses.length,
              itemBuilder: (context, i) {
                final s        = _filterStatuses[i];
                final selected = _statusFilter == s;
                final count    = s == 'all' ? _all.length : _all.where((p) => p['status'] == s).length;
                return GestureDetector(
                  onTap: () => setState(() { _statusFilter = s; _applyFilter(); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1)} ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(color: const Color(0xFFF4F6F5), borderRadius: BorderRadius.circular(20)),
                                child: const Icon(Icons.description_outlined, size: 40, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              const Text('No prescriptions found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              const Text('Prescriptions shared by customers appear here', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ]),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final rx      = _filtered[i];
                                final profile = rx['profiles'] as Map<String, dynamic>? ?? {};
                                final status  = rx['status'] as String? ?? 'pending';
                                String uploadDate = '';
                                try {
                                  uploadDate = DateFormat('d MMM yyyy').format(
                                    DateTime.parse(rx['uploaded_at'] as String));
                                } catch (_) {}

                                return GestureDetector(
                                  onTap: () => _showDetail(rx),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: status == 'pending'
                                          ? Border.all(color: AppColors.warning.withAlpha(80), width: 1.5)
                                          : null,
                                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withAlpha(20),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(_statusIcon(status), color: _statusColor(status), size: 24),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(rx['prescription_number'] as String? ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                              const SizedBox(height: 2),
                                              Text(profile['customer_name'] as String? ?? 'Customer',
                                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                              if (rx['doctor_name'] != null) ...[
                                                const SizedBox(height: 1),
                                                Text('Dr. ${rx['doctor_name']}',
                                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                              ],
                                              const SizedBox(height: 4),
                                              Text(uploadDate, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withAlpha(20),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                status[0].toUpperCase() + status.substring(1),
                                                style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            if (status == 'pending') ...[
                                              const SizedBox(height: 6),
                                              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Detail bottom sheet ──────────────────────────────────────────────────────

class _PrescriptionDetailSheet extends StatelessWidget {
  final Map<String, dynamic> rx;
  final void Function(String) onUpdateStatus;

  const _PrescriptionDetailSheet({required this.rx, required this.onUpdateStatus});

  Color _statusColor(String s) => switch (s) {
    'pending'  => AppColors.warning,
    'verified' => AppColors.success,
    'rejected' => AppColors.error,
    'expired'  => AppColors.textSecondary,
    _          => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final profile  = rx['profiles'] as Map<String, dynamic>? ?? {};
    final status   = rx['status'] as String? ?? 'pending';
    final imageUrl = rx['prescription_image'] as String?;
    final isPending = status == 'pending';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
              )),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rx['prescription_number'] as String? ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(profile['customer_name'] as String? ?? 'Customer',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              if (profile['customer_contact'] != null) ...[
                                const SizedBox(height: 2),
                                Text(profile['customer_contact'] as String,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _statusColor(status).withAlpha(60)),
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Prescription image
                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                      const Text('Prescription Image', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          placeholder: (ctx, url) => Container(
                            height: 200, color: const Color(0xFFF4F6F5),
                            child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                          ),
                          errorWidget: (ctx, url, err) => Container(
                            height: 120, color: const Color(0xFFF4F6F5),
                            child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 40)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Info rows
                    const Text('Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 12),
                    if (rx['doctor_name'] != null)
                      _infoRow(Icons.medical_services_outlined, 'Doctor', 'Dr. ${rx['doctor_name']}'),
                    if (rx['doctor_license'] != null)
                      _infoRow(Icons.badge_outlined, 'License', rx['doctor_license'] as String),
                    if (rx['issue_date'] != null)
                      _infoRow(Icons.calendar_today_outlined, 'Issue Date', rx['issue_date'] as String),
                    if (rx['expiry_date'] != null)
                      _infoRow(Icons.event_busy_outlined, 'Expiry Date', rx['expiry_date'] as String),
                    if (rx['prescription_notes'] != null && (rx['prescription_notes'] as String).isNotEmpty)
                      _infoRow(Icons.notes_outlined, 'Notes', rx['prescription_notes'] as String),

                    const SizedBox(height: 24),

                    // Action buttons
                    if (isPending) ...[
                      const Text('Review Decision', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onUpdateStatus('rejected'),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => onUpdateStatus('verified'),
                              icon: const Icon(Icons.verified_rounded, size: 18),
                              label: const Text('Verify'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onUpdateStatus('pending'),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reset to Pending'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/prescription_provider.dart';
import '../../widgets/empty_state.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().fetchPrescriptions();
    });
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending'  => AppColors.warning,
      'verified' => AppColors.success,
      'rejected' => AppColors.error,
      'expired'  => AppColors.textSecondary,
      _          => AppColors.textSecondary,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'pending'  => Icons.hourglass_empty,
      'verified' => Icons.verified,
      'rejected' => Icons.cancel_outlined,
      'expired'  => Icons.event_busy,
      _          => Icons.description_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PrescriptionProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Prescriptions')),
      floatingActionButton: pp.prescriptions.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/upload-prescription'),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
      body: pp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : pp.prescriptions.isEmpty
              ? EmptyState(
                  icon: Icons.description_outlined,
                  title: 'No prescriptions yet',
                  subtitle: 'Upload your first prescription to get started.',
                  actionLabel: 'Upload Prescription',
                  onAction: () => Navigator.pushNamed(context, '/upload-prescription'),
                )
              : RefreshIndicator(
                  onRefresh: () => pp.fetchPrescriptions(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: pp.prescriptions.length,
                    itemBuilder: (context, i) {
                      final rx = pp.prescriptions[i];
                      String uploadDate = '';
                      try { uploadDate = DateFormat('d MMM yyyy').format(DateTime.parse(rx.uploadedAt ?? '')); }
                      catch (_) { uploadDate = rx.uploadedAt ?? ''; }

                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/prescription-detail', arguments: rx),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _statusColor(rx.status).withAlpha(26),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_statusIcon(rx.status), color: _statusColor(rx.status), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rx.prescriptionNumber,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                    if (rx.doctorName != null && rx.doctorName!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('Dr. ${rx.doctorName}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150), fontSize: 12)),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(uploadDate, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(120), fontSize: 11)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(rx.status).withAlpha(26),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      rx.status.toUpperCase(),
                                      style: TextStyle(color: _statusColor(rx.status), fontSize: 10, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../models/pharmacy_model.dart';

class SavedPharmaciesScreen extends StatefulWidget {
  const SavedPharmaciesScreen({super.key});

  @override
  State<SavedPharmaciesScreen> createState() => _SavedPharmaciesScreenState();
}

class _SavedPharmaciesScreenState extends State<SavedPharmaciesScreen> {
  List<PharmacyModel> _pharmacies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final list = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('customer_type', 'pharmacy');
      if (mounted) {
        setState(() {
          _pharmacies = list.map((e) => PharmacyModel.fromJson(e)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Partner Pharmacies')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _pharmacies.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_pharmacy_outlined, size: 56, color: AppColors.divider),
                      SizedBox(height: 12),
                      Text('No pharmacies found', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pharmacies.length,
                    itemBuilder: (context, i) {
                      final p = _pharmacies[i];
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/pharmacy-detail', arguments: p),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 54, height: 54,
                                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                                    if (p.customerCity != null) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 3),
                                          Text(p.customerCity!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                                          child: const Text('Open', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                                        const SizedBox(width: 2),
                                        const Text('4.5', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                        if (p.customerContact != null) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                                          const SizedBox(width: 3),
                                          Text(p.customerContact!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
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

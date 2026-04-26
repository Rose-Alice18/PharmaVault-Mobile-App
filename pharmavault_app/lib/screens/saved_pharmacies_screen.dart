import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_bookmark_service.dart';

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
      final savedIds = await PharmacyBookmarkService.getSavedIds();
      if (savedIds.isEmpty) {
        if (mounted) setState(() { _pharmacies = []; _loading = false; });
        return;
      }
      final list = await Supabase.instance.client
          .from('profiles')
          .select()
          .inFilter('id', savedIds)
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

  Future<void> _unsave(PharmacyModel p) async {
    await PharmacyBookmarkService.toggle(p.customerId);
    setState(() => _pharmacies.removeWhere((x) => x.customerId == p.customerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Saved Pharmacies')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _pharmacies.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline_rounded, size: 56, color: AppColors.divider),
                      SizedBox(height: 12),
                      Text('No saved pharmacies',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Bookmark pharmacies you like to see them here',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center),
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
                        onTap: () async {
                          await Navigator.pushNamed(context, '/pharmacy-detail', arguments: p);
                          _fetch();
                        },
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
                                decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.local_pharmacy_rounded,
                                    color: AppColors.primary, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.customerName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.textPrimary)),
                                    if (p.customerCity != null) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined,
                                              size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 3),
                                          Text(p.customerCity!,
                                              style: const TextStyle(
                                                  color: AppColors.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(20)),
                                          child: const Text('Open',
                                              style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star_rounded,
                                            color: Color(0xFFFBBF24), size: 13),
                                        const SizedBox(width: 2),
                                        const Text('4.5',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.bookmark_remove_rounded,
                                    color: AppColors.error, size: 22),
                                tooltip: 'Remove',
                                onPressed: () => _unsave(p),
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

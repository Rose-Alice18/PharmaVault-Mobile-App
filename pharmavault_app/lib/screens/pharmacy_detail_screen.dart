import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/supabase_constants.dart';
import '../models/pharmacy_model.dart';
import '../providers/cart_provider.dart';

class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({super.key});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pharmacy = ModalRoute.of(context)!.settings.arguments as PharmacyModel;
    _fetchProducts(pharmacy.customerId);
  }

  Future<void> _fetchProducts(String pharmacyId) async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('pharmacy_products')
          .select('pharmacy_price, stock_count, products(product_id, product_title, product_image, product_keywords, brands(brand_name))')
          .eq('pharmacy_id', pharmacyId)
          .eq('is_available', true);
      if (mounted) setState(() => _products = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacy = ModalRoute.of(context)!.settings.arguments as PharmacyModel;
    final cart     = context.read<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primary,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16, right: 16, bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(pharmacy.customerName,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white.withAlpha(100)),
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                                ),
                              ],
                            ),
                            if (pharmacy.customerCity != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                  Text(pharmacy.customerCity!,
                                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatChip(icon: Icons.star_rounded, label: '4.5', color: const Color(0xFFFBBF24)),
                      const SizedBox(width: 8),
                      const _StatChip(icon: Icons.access_time_rounded, label: '8AM – 9PM'),
                      const SizedBox(width: 8),
                      const _StatChip(icon: Icons.circle, label: 'Open', color: Color(0xFF4ADE80)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.phone_rounded,
                          label: 'Call',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(pharmacy.customerContact != null
                                  ? 'Calling ${pharmacy.customerContact}...'
                                  : 'No contact available'),
                            ));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.directions_rounded,
                          label: 'Directions',
                          onTap: () async {
                            final Uri url = pharmacy.lat != null && pharmacy.lng != null
                                ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${pharmacy.lat},${pharmacy.lng}')
                                : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(pharmacy.customerName)}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Section header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available Medicines',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(
                    _loading ? '' : '${_products.length} item${_products.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // ── Product list ─────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
            )
          else if (_products.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text('No medicines listed yet', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final row        = _products[i];
                  final product    = row['products'] as Map<String, dynamic>;
                  final brand      = product['brands'] as Map<String, dynamic>?;
                  final price      = (row['pharmacy_price'] as num).toDouble();
                  final stock      = row['stock_count'] as int;
                  final productId  = product['product_id'] as int;
                  final imageUrl   = SupabaseConstants.imageUrl(product['product_image'] as String?);
                  final isRx       = (product['product_keywords'] as String?)?.toLowerCase().contains('rx') ?? false;

                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: productId),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 60, height: 60,
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl, fit: BoxFit.cover,
                                          placeholder: (ctx, url) => Container(color: const Color(0xFFF4F6F5)),
                                          errorWidget: (ctx, url, err) => Container(
                                            color: const Color(0xFFF4F6F5),
                                            child: const Icon(Icons.medication_rounded, color: AppColors.primary),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFFF4F6F5),
                                          child: const Icon(Icons.medication_rounded, color: AppColors.primary),
                                        ),
                                ),
                              ),
                              if (isRx)
                                Positioned(
                                  top: 2, right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Rx', style: TextStyle(color: Color(0xFFD97706), fontSize: 8, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['product_title'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (brand != null)
                                  Text(brand['brand_name'] as String,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stock > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        stock > 0 ? '$stock in stock' : 'Out of stock',
                                        style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.w600,
                                          color: stock > 0 ? AppColors.primary : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('GHS ${price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                              const SizedBox(height: 6),
                              if (stock > 0)
                                GestureDetector(
                                  onTap: () async {
                                    final ok = await cart.addItem(productId);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(ok ? 'Added to cart!' : cart.error ?? 'Failed.'),
                                      backgroundColor: ok ? AppColors.success : AppColors.error,
                                      duration: const Duration(seconds: 2),
                                    ));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _products.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

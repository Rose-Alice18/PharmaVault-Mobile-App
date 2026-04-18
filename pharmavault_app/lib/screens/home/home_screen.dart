import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';
import '../../models/pharmacy_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PharmacyModel> _pharmacies = [];
  bool _pharmaciesLoading = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      final pp = context.read<ProductProvider>();
      pp.fetchProducts(limit: 10);
      pp.fetchCategories();
      _fetchPharmacies();
    }
  }

  Future<void> _fetchPharmacies() async {
    setState(() => _pharmaciesLoading = true);
    try {
      final list = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('customer_type', 'pharmacy');
      if (mounted) {
        setState(() {
          _pharmacies = list
              .map((e) => PharmacyModel.fromJson(e))
              .toList();
        });
      }
    } catch (_) {
      // non-critical
    } finally {
      if (mounted) setState(() => _pharmaciesLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    final pp = context.read<ProductProvider>();
    await Future.wait([
      pp.fetchProducts(limit: 10),
      pp.fetchCategories(),
      _fetchPharmacies(),
    ]);
  }

  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('pain') || n.contains('analges')) return Icons.healing_rounded;
    if (n.contains('antibiotic') || n.contains('antibac')) return Icons.biotech_rounded;
    if (n.contains('vitamin') || n.contains('supplement') || n.contains('mineral')) return Icons.local_florist_rounded;
    if (n.contains('diabet') || n.contains('insulin')) return Icons.monitor_heart_rounded;
    if (n.contains('malaria') || n.contains('antimalar')) return Icons.coronavirus_rounded;
    if (n.contains('digest') || n.contains('gastro') || n.contains('stomach')) return Icons.restaurant_rounded;
    if (n.contains('skin') || n.contains('derm') || n.contains('topical')) return Icons.face_retouching_natural_rounded;
    if (n.contains('first aid') || n.contains('emergency') || n.contains('wound')) return Icons.medical_services_rounded;
    if (n.contains('cold') || n.contains('flu') || n.contains('cough') || n.contains('respiratory')) return Icons.sick_rounded;
    if (n.contains('heart') || n.contains('cardio') || n.contains('blood pressure')) return Icons.favorite_rounded;
    if (n.contains('eye') || n.contains('ophthalm')) return Icons.remove_red_eye_rounded;
    if (n.contains('child') || n.contains('pediatric') || n.contains('baby')) return Icons.child_care_rounded;
    return Icons.medication_rounded;
  }

  Color _categoryColor(int index) {
    const colors = [
      Color(0xFFDCFCE7), // green
      Color(0xFFDBEAFE), // blue
      Color(0xFFFEF3C7), // amber
      Color(0xFFFCE7F3), // pink
      Color(0xFFE0E7FF), // indigo
      Color(0xFFD1FAE5), // emerald
      Color(0xFFFEE2E2), // red
      Color(0xFFF3E8FF), // purple
    ];
    return colors[index % colors.length];
  }

  Color _categoryIconColor(int index) {
    const colors = [
      AppColors.primary,
      Color(0xFF2563EB),
      Color(0xFFD97706),
      Color(0xFFDB2777),
      Color(0xFF4F46E5),
      Color(0xFF059669),
      Color(0xFFDC2626),
      Color(0xFF7C3AED),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pp   = context.watch<ProductProvider>();
    final cart = context.read<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Green header ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.primary,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Deliver to Accra, Ghana',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/notifications'),
                          child: Stack(
                            children: [
                              const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                              Positioned(
                                right: 0, top: 0,
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hello, ${auth.customerName?.split(' ').first ?? 'there'}!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'What medicine do you need today?',
                      style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200)),
                    ),
                    const SizedBox(height: 14),
                    // Search bar
                    GestureDetector(
                      onTap: () {
                        // Navigate to search tab (index 1) via main screen
                        DefaultTabController.of(context);
                        Navigator.pushNamed(context, '/search');
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Search medicines, pharmacies...',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Upload Prescription banner ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/upload-prescription'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF15803D), Color(0xFF16A34A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Upload Prescription',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Get medicines delivered from your prescription',
                                    style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Shop by Category ──────────────────────────────────────
                  if (pp.categories.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Shop by Category',
                      onSeeAll: () => Navigator.pushNamed(context, '/search'),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: pp.categories.length,
                        itemBuilder: (context, i) {
                          final cat = pp.categories[i];
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/search', arguments: {'catId': cat.catId}),
                            child: Container(
                              width: 76,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: _categoryColor(i),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(_categoryIcon(cat.catName), color: _categoryIconColor(i), size: 26),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cat.catName,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // ── Popular Medicines ─────────────────────────────────────
                  _SectionHeader(
                    title: 'Popular Medicines',
                    onSeeAll: () => Navigator.pushNamed(context, '/search'),
                  ),
                  if (pp.isLoading)
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else if (pp.products.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: pp.products.length,
                        itemBuilder: (context, i) => _ProductHCard(
                          product: pp.products[i],
                          onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: pp.products[i].productId),
                          onAddToCart: pp.products[i].productStock > 0
                              ? () async {
                                  final ok = await cart.addItem(pp.products[i].productId);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(ok ? '${pp.products[i].productTitle} added!' : cart.error ?? 'Failed.'),
                                    backgroundColor: ok ? AppColors.success : AppColors.error,
                                    duration: const Duration(seconds: 2),
                                  ));
                                }
                              : null,
                        ),
                      ),
                    ),

                  // ── Nearby Pharmacies ─────────────────────────────────────
                  if (_pharmacies.isNotEmpty || _pharmaciesLoading) ...[
                    _SectionHeader(
                      title: 'Partner Pharmacies',
                      onSeeAll: () => Navigator.pushNamed(context, '/saved-pharmacies'),
                    ),
                    if (_pharmaciesLoading)
                      const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _pharmacies.length > 4 ? 4 : _pharmacies.length,
                        itemBuilder: (context, i) => _PharmacyCard(
                          pharmacy: _pharmacies[i],
                          onTap: () => Navigator.pushNamed(context, '/pharmacy-detail', arguments: _pharmacies[i]),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See All', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _ProductHCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  const _ProductHCard({required this.product, required this.onTap, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final imageUrl = SupabaseConstants.imageUrl(product.productImage);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(color: AppColors.primaryLight),
                        errorWidget: (ctx, url, err) => Container(
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.medication, size: 36, color: AppColors.primary),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.medication, size: 36, color: AppColors.primary),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GHS ${product.productPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        if (onAddToCart != null)
                          GestureDetector(
                            onTap: onAddToCart,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.add, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
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
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final VoidCallback onTap;
  const _PharmacyCard({required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  if (pharmacy.customerCity != null)
                    Text(pharmacy.customerCity!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Open', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                      const SizedBox(width: 2),
                      const Text('4.5', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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
  }
}

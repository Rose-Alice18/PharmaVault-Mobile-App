import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';
import '../../models/pharmacy_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final pp = context.read<ProductProvider>();
        pp.fetchProducts(limit: 10);
        pp.fetchCategories();
        _fetchPharmacies();
      });
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
          _pharmacies = list.map((e) => PharmacyModel.fromJson(e)).toList();
        });
      }
    } catch (_) {}
    finally {
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

  String _greeting(String? firstName) {
    final hour = DateTime.now().hour;
    final salut = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return '$salut, ${firstName ?? 'there'}!';
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
      Color(0xFFDCFCE7),
      Color(0xFFDBEAFE),
      Color(0xFFFEF3C7),
      Color(0xFFFCE7F3),
      Color(0xFFE0E7FF),
      Color(0xFFD1FAE5),
      Color(0xFFFEE2E2),
      Color(0xFFF3E8FF),
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
    final auth      = context.watch<AuthProvider>();
    final pp        = context.watch<ProductProvider>();
    final cart      = context.read<CartProvider>();
    final location  = context.watch<LocationProvider>();
    final firstName = auth.customerName?.split(' ').first;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Theme.of(context).cardColor,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    right: 20,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location row + notification
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  Text(
                                    location.cityName,
                                    style: TextStyle(
                                      color: onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 16),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/notifications'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF4F6F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.notifications_outlined, color: onSurface, size: 22),
                                  Positioned(
                                    right: 8, top: 8,
                                    child: Container(
                                      width: 7, height: 7,
                                      decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Greeting
                      Text(
                        _greeting(firstName),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: onSurface),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'What medicine do you need today?',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/search'),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF4F6F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                              const SizedBox(width: 10),
                              const Text(
                                'Search medicines, pharmacies...',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Divider ───────────────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Prescription banner ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/upload-prescription'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B8A4C), Color(0xFF34C77B)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Upload a Prescription',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Get your medicines delivered fast',
                                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Shop by Category ──────────────────────────────────
                    if (pp.categories.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Shop by Category',
                        onSeeAll: () => Navigator.pushNamed(context, '/search'),
                      ),
                      SizedBox(
                        height: 104,
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
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _categoryColor(i),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(_categoryIcon(cat.catName), color: _categoryIconColor(i), size: 28),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat.catName,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // ── Popular Medicines ─────────────────────────────────
                    _SectionHeader(
                      title: 'Popular Medicines',
                      onSeeAll: () => Navigator.pushNamed(context, '/search'),
                    ),
                    if (pp.isLoading)
                      const SizedBox(
                        height: 230,
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                      )
                    else if (pp.products.isNotEmpty)
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: pp.products.length,
                          itemBuilder: (context, i) => _ProductCard(
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

                    // ── Partner Pharmacies ────────────────────────────────
                    if (_pharmacies.isNotEmpty || _pharmaciesLoading) ...[
                      _SectionHeader(
                        title: 'Partner Pharmacies',
                        onSeeAll: () => Navigator.pushNamed(context, '/saved-pharmacies'),
                      ),
                      if (_pharmaciesLoading)
                        const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _pharmacies.length > 4 ? 4 : _pharmacies.length,
                          itemBuilder: (context, i) => _PharmacyCard(
                            pharmacy: _pharmacies[i],
                            distanceLabel: location.distanceLabel(_pharmacies[i].lat, _pharmacies[i].lng),
                            onTap: () => Navigator.pushNamed(context, '/pharmacy-detail', arguments: _pharmacies[i]),
                          ),
                        ),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
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

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  const _ProductCard({required this.product, required this.onTap, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final imageUrl = SupabaseConstants.imageUrl(product.productImage);
    final isRx = product.productKeywords?.toLowerCase().contains('rx') ?? false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(color: const Color(0xFFF4F6F5)),
                            errorWidget: (ctx, url, err) => Container(
                              color: const Color(0xFFF4F6F5),
                              child: const Icon(Icons.medication_rounded, size: 40, color: AppColors.primary),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF4F6F5),
                            child: const Icon(Icons.medication_rounded, size: 40, color: AppColors.primary),
                          ),
                  ),
                ),
                if (isRx)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Rx', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
                if (product.productStock == 0)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Out of stock', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface, height: 1.3),
                    ),
                    if (product.brandName != null) ...[
                      const SizedBox(height: 2),
                      Text(product.brandName!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GHS ${product.productPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                        if (onAddToCart != null)
                          GestureDetector(
                            onTap: onAddToCart,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
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
  final String distanceLabel;
  const _PharmacyCard({required this.pharmacy, required this.onTap, this.distanceLabel = ''});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.customerName,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 3),
                  if (pharmacy.customerCity != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(pharmacy.customerCity!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Badge(label: 'Open', bgColor: const Color(0xFFDCFCE7), textColor: AppColors.primary),
                      const SizedBox(width: 6),
                      _Badge(label: 'Free Delivery', bgColor: const Color(0xFFDBEAFE), textColor: const Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                      const SizedBox(width: 2),
                      const Text('4.5', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      if (distanceLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.near_me_rounded, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(distanceLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _Badge({required this.label, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/supabase_constants.dart';
import '../utils/validators.dart';
import '../models/pharmacy_model.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../providers/product_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();
  final _speech     = SpeechToText();
  bool _isListening = false;
  int? _selectedCatId;

  List<PharmacyModel> _pharmacies = [];
  List<PharmacyModel> _filteredPharmacies = [];
  bool _pharmaciesLoading = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      final pp = context.read<ProductProvider>();
      pp.fetchProducts();
      pp.fetchCategories();
      _fetchPharmacies();

      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['catId'] != null) {
        _selectedCatId = args['catId'] as int;
        pp.fetchProducts(catId: _selectedCatId);
      }
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
          _filteredPharmacies = _pharmacies;
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _pharmaciesLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    final pp    = context.read<ProductProvider>();
    final clean = AppValidators.sanitizeSearch(_searchCtrl.text);
    await Future.wait([
      pp.fetchProducts(search: clean.isEmpty ? null : clean, catId: _selectedCatId),
      _fetchPharmacies(),
    ]);
  }

  void _onSearch(String query) {
    final clean = AppValidators.sanitizeSearch(query);
    if (_tabController.index == 0) {
      context.read<ProductProvider>().fetchProducts(
        search: clean.isEmpty ? null : clean,
        catId: _selectedCatId,
      );
    } else {
      setState(() {
        _filteredPharmacies = clean.isEmpty
            ? _pharmacies
            : _pharmacies.where((p) =>
                p.customerName.toLowerCase().contains(clean.toLowerCase()) ||
                (p.customerCity?.toLowerCase().contains(clean.toLowerCase()) ?? false)).toList();
      });
    }
  }

  void _filterByCat(int? catId) {
    setState(() => _selectedCatId = catId);
    context.read<ProductProvider>().fetchProducts(
      catId: catId,
      search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
    );
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') setState(() => _isListening = false);
      },
      onError: (_) => setState(() => _isListening = false),
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone not available')),
        );
      }
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() => _searchCtrl.text = result.recognizedWords);
        if (result.finalResult) {
          _onSearch(result.recognizedWords);
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor:  const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tabController.dispose();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp       = context.watch<ProductProvider>();
    final cart     = context.read<CartProvider>();
    final location = context.watch<LocationProvider>();
    final resultCount = _tabController.index == 0 ? pp.products.length : _filteredPharmacies.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              color: Theme.of(context).cardColor,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                left: 20, right: 20, bottom: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: onSurface),
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      onChanged: _onSearch,
                      inputFormatters: AppFormatters.search,
                      style: TextStyle(fontSize: 14, color: onSurface),
                      decoration: InputDecoration(
                        hintText: _tabController.index == 0
                            ? 'Search medicines, brands...'
                            : 'Search pharmacies...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                        suffixIcon: _isListening
                            ? IconButton(
                                icon: const Icon(Icons.stop_circle_rounded, size: 22, color: AppColors.error),
                                onPressed: _toggleListening,
                              )
                            : _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textSecondary),
                                    onPressed: () { setState(() => _searchCtrl.clear()); _onSearch(''); },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.mic_rounded, size: 20, color: AppColors.textSecondary),
                                    onPressed: _toggleListening,
                                  ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_isListening) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.mic_rounded, size: 13, color: AppColors.error),
                        const SizedBox(width: 4),
                        const Text('Listening...', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Result count
                  if (!pp.isLoading && !_pharmaciesLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '$resultCount result${resultCount == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),

            // ── Tabs ─────────────────────────────────────────────────────
            Container(
              color: Theme.of(context).cardColor,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Medicines'),
                        if (pp.products.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                            child: Text('${pp.products.length}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pharmacies'),
                        if (_filteredPharmacies.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                            child: Text('${_filteredPharmacies.length}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

            // ── Tab content ───────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primary,
                child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Medicines ──────────────────────────────────────────
                  Column(
                    children: [
                      if (pp.categories.isNotEmpty)
                        Container(
                          color: Theme.of(context).cardColor,
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            itemCount: pp.categories.length + 1,
                            itemBuilder: (context, i) {
                              final isAll    = i == 0;
                              final catId    = isAll ? null : pp.categories[i - 1].catId;
                              final label    = isAll ? 'All' : pp.categories[i - 1].catName;
                              final selected = _selectedCatId == catId;
                              final isDarkInner = Theme.of(context).brightness == Brightness.dark;
                              return GestureDetector(
                                onTap: () => _filterByCat(catId),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: selected ? AppColors.primary : (isDarkInner ? const Color(0xFF1F2937) : const Color(0xFFF4F6F5)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    label,
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
                      Expanded(
                        child: pp.isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                            : pp.products.isEmpty
                                ? _EmptyState(
                                    icon: Icons.search_off_rounded,
                                    title: 'No medicines found',
                                    subtitle: 'Try a different search term',
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                                    itemCount: pp.products.length,
                                    itemBuilder: (context, i) {
                                      final product  = pp.products[i];
                                      final imageUrl = SupabaseConstants.imageUrl(product.productImage);
                                      final isRx     = product.productKeywords?.toLowerCase().contains('rx') ?? false;
                                      return GestureDetector(
                                        onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product.productId),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
                                          ),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: SizedBox(
                                                  width: 72,
                                                  height: 72,
                                                  child: imageUrl.isNotEmpty
                                                      ? CachedNetworkImage(
                                                          imageUrl: imageUrl,
                                                          fit: BoxFit.cover,
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
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            product.productTitle,
                                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (isRx) ...[
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                                            child: const Text('Rx', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w800)),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    if (product.brandName != null) ...[
                                                      const SizedBox(height: 1),
                                                      Text(product.brandName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                                    ],
                                                    if (product.catName != null)
                                                      Text(product.catName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          'GHS ${product.productPrice.toStringAsFixed(2)}',
                                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                                                        ),
                                                        if (product.productStock > 0)
                                                          GestureDetector(
                                                            onTap: () async {
                                                              final ok = await cart.addItem(product.productId);
                                                              if (!context.mounted) return;
                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                content: Text(ok ? 'Added to cart!' : cart.error ?? 'Failed.'),
                                                                backgroundColor: ok ? AppColors.success : AppColors.error,
                                                                duration: const Duration(seconds: 2),
                                                              ));
                                                            },
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                                                              child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                                            ),
                                                          )
                                                        else
                                                          const Text('Out of stock', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),

                  // ── Pharmacies ─────────────────────────────────────────
                  _pharmaciesLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                      : _filteredPharmacies.isEmpty
                          ? _EmptyState(
                              icon: Icons.local_pharmacy_outlined,
                              title: 'No pharmacies found',
                              subtitle: 'Try a different search term',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                              itemCount: _filteredPharmacies.length,
                              itemBuilder: (context, i) {
                                final p = _filteredPharmacies[i];
                                return GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/pharmacy-detail', arguments: p),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
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
                                              Text(p.customerName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                              if (p.customerCity != null) ...[
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textSecondary),
                                                    const SizedBox(width: 2),
                                                    Text(p.customerCity!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  _Tag(label: 'Open', bgColor: const Color(0xFFDCFCE7), textColor: AppColors.primary),
                                                  const SizedBox(width: 6),
                                                  _Tag(label: 'Delivery', bgColor: const Color(0xFFDBEAFE), textColor: const Color(0xFF2563EB)),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                                                  const SizedBox(width: 2),
                                                  const Text('4.5', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                                  Builder(builder: (_) {
                                                    final dist = location.distanceLabel(p.lat, p.lng);
                                                    if (dist.isEmpty) return const SizedBox.shrink();
                                                    return Row(children: [
                                                      const SizedBox(width: 6),
                                                      const Icon(Icons.near_me_rounded, size: 11, color: AppColors.textSecondary),
                                                      const SizedBox(width: 2),
                                                      Text(dist, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                                    ]);
                                                  }),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
                                      ],
                                    ),
                                  ),
                                );
                              },
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

class _Tag extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _Tag({required this.label, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: const Color(0xFFF4F6F5), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 40, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

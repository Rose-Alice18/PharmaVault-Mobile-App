import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/supabase_constants.dart';
import '../models/pharmacy_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  int? _selectedCatId;

  List<PharmacyModel> _pharmacies = [];
  List<PharmacyModel> _filteredPharmacies = [];
  bool _pharmaciesLoading = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

      // Handle arguments if navigated with a catId
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
    } catch (_) {
    } finally {
      if (mounted) setState(() => _pharmaciesLoading = false);
    }
  }

  void _onSearch(String query) {
    if (_tabController.index == 0) {
      context.read<ProductProvider>().fetchProducts(
            search: query.isEmpty ? null : query,
            catId: _selectedCatId,
          );
    } else {
      setState(() {
        _filteredPharmacies = query.isEmpty
            ? _pharmacies
            : _pharmacies
                .where((p) =>
                    p.customerName.toLowerCase().contains(query.toLowerCase()) ||
                    (p.customerCity?.toLowerCase().contains(query.toLowerCase()) ?? false))
                .toList();
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp   = context.watch<ProductProvider>();
    final cart = context.read<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0
                        ? 'Search medicines, brands...'
                        : 'Search pharmacies...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
                onTap: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Medicines tab ────────────────────────────────────────────────
          Column(
            children: [
              // Category filter chips
              if (pp.categories.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: pp.categories.length + 1,
                    itemBuilder: (context, i) {
                      final isAll = i == 0;
                      final catId = isAll ? null : pp.categories[i - 1].catId;
                      final label = isAll ? 'All' : pp.categories[i - 1].catName;
                      final selected = _selectedCatId == catId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                          selected: selected,
                          onSelected: (_) => _filterByCat(catId),
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: pp.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : pp.products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 56, color: AppColors.divider),
                                const SizedBox(height: 12),
                                const Text('No medicines found', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text('Try a different search term', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: pp.products.length,
                            itemBuilder: (context, i) {
                              final product = pp.products[i];
                              final imageUrl = SupabaseConstants.imageUrl(product.productImage);
                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product.productId),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 68,
                                          height: 68,
                                          child: imageUrl.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  fit: BoxFit.cover,
                                                  placeholder: (ctx, url) => Container(color: AppColors.primaryLight),
                                                  errorWidget: (ctx, url, err) => Container(color: AppColors.primaryLight, child: const Icon(Icons.medication, color: AppColors.primary)),
                                                )
                                              : Container(color: AppColors.primaryLight, child: const Icon(Icons.medication, color: AppColors.primary)),
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
                                                  child: Text(product.productTitle,
                                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ),
                                                if (product.productKeywords != null && product.productKeywords!.toLowerCase().contains('rx'))
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                                    child: const Text('Rx', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w700)),
                                                  ),
                                              ],
                                            ),
                                            if (product.brandName != null)
                                              Text(product.brandName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                            if (product.catName != null)
                                              Text(product.catName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('GHS ${product.productPrice.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
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
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                                      child: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                                    ),
                                                  )
                                                else
                                                  const Text('Out of stock', style: TextStyle(color: AppColors.error, fontSize: 11)),
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

          // ── Pharmacies tab ───────────────────────────────────────────────
          _pharmaciesLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _filteredPharmacies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_pharmacy_outlined, size: 56, color: AppColors.divider),
                          const SizedBox(height: 12),
                          const Text('No pharmacies found', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPharmacies.length,
                      itemBuilder: (context, i) {
                        final p = _filteredPharmacies[i];
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/pharmacy-detail', arguments: p),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 26),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                      if (p.customerCity != null) ...[
                                        const SizedBox(height: 2),
                                        Text(p.customerCity!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      ],
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                                            child: const Text('Open', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                                          const SizedBox(width: 2),
                                          const Text('4.5', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                          if (p.customerContact != null) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                                            const SizedBox(width: 2),
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
        ],
      ),
    );
  }
}

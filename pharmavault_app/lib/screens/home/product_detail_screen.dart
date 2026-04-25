import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_button.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _loaded = false;
  int  _qty    = 1;
  List<Map<String, dynamic>> _pharmacies = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final id = ModalRoute.of(context)!.settings.arguments as int;
      context.read<ProductProvider>().fetchProductById(id);
      _fetchPharmacies(id);
    }
  }

  Future<void> _fetchPharmacies(int productId) async {
    try {
      final data = await Supabase.instance.client
          .from('pharmacy_products')
          .select('pharmacy_price, stock_count, profiles(customer_name, customer_city)')
          .eq('product_id', productId)
          .eq('is_available', true)
          .order('pharmacy_price');
      if (mounted) setState(() => _pharmacies = List<Map<String, dynamic>>.from(data));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pp      = context.watch<ProductProvider>();
    final cart    = context.read<CartProvider>();
    final product = pp.selected;

    if (pp.isLoading || product == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: AppColors.textPrimary, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final imageUrl = SupabaseConstants.imageUrl(product.productImage);
    final inStock  = product.productStock > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image hero ─────────────────────────────────────────
                    Stack(
                      children: [
                        Container(
                          height: 300,
                          width: double.infinity,
                          color: AppColors.primaryLight,
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (ctx, url) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                                  errorWidget: (ctx, url, err) => const Center(child: Icon(Icons.medication, size: 80, color: AppColors.primary)),
                                )
                              : const Center(child: Icon(Icons.medication, size: 80, color: AppColors.primary)),
                        ),
                        // Back button
                        Positioned(
                          top: 12, left: 12,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8)],
                              ),
                              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                            ),
                          ),
                        ),
                        // Stock badge
                        Positioned(
                          top: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: inStock ? AppColors.success : AppColors.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              inStock ? 'In Stock' : 'Out of Stock',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Info card ──────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category chip
                          if (product.catName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(product.catName!, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            product.productTitle,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          if (product.brandName != null) ...[
                            const SizedBox(height: 4),
                            Text('by ${product.brandName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            'GHS ${product.productPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                          if (inStock) ...[
                            const SizedBox(height: 4),
                            Text('${product.productStock} units available', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Description ────────────────────────────────────────
                    _InfoSection(
                      title: 'Description',
                      child: Text(
                        product.productDescription.isNotEmpty ? product.productDescription : 'No description available.',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.7),
                      ),
                    ),

                    // ── Dosage info ────────────────────────────────────────
                    _InfoSection(
                      title: 'Dosage Information',
                      child: Column(
                        children: [
                          _DosageRow(label: 'Adults', value: 'As directed by pharmacist'),
                          _DosageRow(label: 'Children', value: 'Consult a doctor'),
                          _DosageRow(label: 'Frequency', value: 'As prescribed'),
                          _DosageRow(label: 'Route', value: 'Oral / Topical'),
                        ],
                      ),
                    ),

                    // ── Side effects warning ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Side Effects', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF92400E))),
                                  SizedBox(height: 4),
                                  Text(
                                    'May cause mild side effects. Consult your doctor or pharmacist for details. Stop use and seek medical advice if adverse reactions occur.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Available At ───────────────────────────────────────
                    _InfoSection(
                      title: 'Available At',
                      child: _pharmacies.isEmpty
                          ? const Text('Not available at any partner pharmacy.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                          : Column(
                              children: _pharmacies.map((row) {
                                final profile = row['profiles'] as Map<String, dynamic>;
                                final price   = (row['pharmacy_price'] as num).toDouble();
                                final stock   = row['stock_count'] as int;
                                final city    = profile['customer_city'] as String?;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F6F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(profile['customer_name'] as String,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                            if (city != null)
                                              Text(city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('GHS ${price.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                                          Text(stock > 0 ? '$stock in stock' : 'Out of stock',
                                              style: TextStyle(fontSize: 10, color: stock > 0 ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    // ── Quantity picker ────────────────────────────────────
                    if (inStock)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _qtyBtn(Icons.remove, () { if (_qty > 1) setState(() => _qty--); }),
                                Container(
                                  width: 48,
                                  alignment: Alignment.center,
                                  child: Text('$_qty', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                ),
                                _qtyBtn(Icons.add, () { if (_qty < product.productStock) setState(() => _qty++); }),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Total', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text(
                                      'GHS ${(product.productPrice * _qty).toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Add to cart button ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: AppButton(
                label: inStock ? 'Add to Cart' : 'Out of Stock',
                onPressed: inStock
                    ? () async {
                        final ok = await cart.addItem(product.productId, qty: _qty);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Added to cart!' : cart.error ?? 'Failed.'),
                          backgroundColor: ok ? AppColors.success : AppColors.error,
                        ));
                        if (ok) Navigator.pop(context);
                      }
                    : null,
                icon: Icons.shopping_cart_outlined,
                isLoading: context.watch<CartProvider>().isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DosageRow extends StatelessWidget {
  final String label;
  final String value;
  const _DosageRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

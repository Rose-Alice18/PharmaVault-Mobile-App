import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';

class PharmacyInventoryScreen extends StatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  State<PharmacyInventoryScreen> createState() => _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends State<PharmacyInventoryScreen> {
  final _db  = SupabaseConstants.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  String? get _uid => _db.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (_uid == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _db
          .from('pharmacy_products')
          .select('id, pharmacy_price, stock_count, is_available, products(product_id, product_title, product_image, product_keywords, brands(brand_name), categories(cat_name))')
          .eq('pharmacy_id', _uid!)
          .order('id');
      setState(() {
        _items = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (_) {
      setState(() { _error = 'Failed to load inventory.'; _loading = false; });
    }
  }

  Future<void> _toggleAvailability(int rowId, bool current) async {
    try {
      await _db.from('pharmacy_products').update({'is_available': !current}).eq('id', rowId);
      await _fetch();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showEditStock(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>? ?? {};
    final ctrl = TextEditingController(text: item['stock_count'].toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit: ${product['product_title'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            _EditField(
              label: 'Stock Count',
              controller: ctrl,
              keyboardType: TextInputType.number,
              prefix: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 14),
            _EditField(
              label: 'Price (GHS)',
              controller: TextEditingController(text: item['pharmacy_price'].toString()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefix: Icons.attach_money_rounded,
              onSaved: (val) async {
                final price = double.tryParse(val);
                if (price != null) {
                  await _db.from('pharmacy_products')
                      .update({'pharmacy_price': price}).eq('id', item['id'] as int);
                }
              },
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final newStock = int.tryParse(ctrl.text);
                  if (newStock == null) return;
                  Navigator.pop(ctx);
                  try {
                    await _db.from('pharmacy_products')
                        .update({'stock_count': newStock}).eq('id', item['id'] as int);
                    await _fetch();
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update stock.'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Inventory'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetch),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : _items.isEmpty
                  ? const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No products in inventory', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item    = _items[i];
                          final product = item['products'] as Map<String, dynamic>? ?? {};
                          final brand   = (product['brands']     as Map<String, dynamic>?)?['brand_name'] as String? ?? '';
                          final cat     = (product['categories'] as Map<String, dynamic>?)?['cat_name']  as String? ?? '';
                          final imgPath = product['product_image'] as String?;
                          final imgUrl  = SupabaseConstants.imageUrl(imgPath);
                          final isAvail = item['is_available'] == true;
                          final stock   = item['stock_count'] as int? ?? 0;
                          final price   = double.tryParse(item['pharmacy_price'].toString()) ?? 0.0;
                          final keywords = product['product_keywords'] as String? ?? '';
                          final isRx    = keywords.toLowerCase().contains('rx');

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
                            ),
                            child: Row(
                              children: [
                                // Product image
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                                  child: SizedBox(
                                    width: 80, height: 90,
                                    child: imgUrl.isNotEmpty
                                        ? CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover,
                                            errorWidget: (context, url, error) => _imgPlaceholder())
                                        : _imgPlaceholder(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Info
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                            child: Text(product['product_title'] as String? ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                                maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ),
                                          if (isRx)
                                            Container(
                                              margin: const EdgeInsets.only(left: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(color: AppColors.error.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                                              child: const Text('Rx', style: TextStyle(fontSize: 9, color: AppColors.error, fontWeight: FontWeight.w800)),
                                            ),
                                        ]),
                                        const SizedBox(height: 3),
                                        Text('$brand • $cat', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          Text('GHS ${price.toStringAsFixed(2)}',
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: stock > 5 ? AppColors.success.withAlpha(20) : AppColors.warning.withAlpha(20),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('Stock: $stock',
                                                style: TextStyle(
                                                  fontSize: 10, fontWeight: FontWeight.w700,
                                                  color: stock > 5 ? AppColors.success : AppColors.warning,
                                                )),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ),
                                // Actions
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Switch(
                                        value: isAvail,
                                        onChanged: (_) => _toggleAvailability(item['id'] as int, isAvail),
                                        activeThumbColor: AppColors.primary,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      Text(isAvail ? 'Active' : 'Hidden',
                                          style: TextStyle(
                                            fontSize: 9, fontWeight: FontWeight.w600,
                                            color: isAvail ? AppColors.primary : AppColors.textSecondary,
                                          )),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => _showEditStock(item),
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AppColors.background,
        child: const Icon(Icons.medication_rounded, color: AppColors.divider, size: 32),
      );
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData prefix;
  final Future<void> Function(String)? onSaved;

  const _EditField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.prefix,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefix, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

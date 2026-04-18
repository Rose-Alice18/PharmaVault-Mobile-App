import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        automaticallyImplyLeading: false,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Remove all items from your cart?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  for (final item in List.from(cart.items)) {
                    await context.read<CartProvider>().removeItem(item.productId);
                  }
                }
              },
              child: const Text('Clear', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: cart.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
              ? EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your cart is empty',
                  subtitle: 'Browse products and add items to your cart.',
                  actionLabel: 'Browse Products',
                  onAction: () => Navigator.pushReplacementNamed(context, '/main'),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => cart.fetchCart(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.items.length,
                          itemBuilder: (context, i) {
                            final item = cart.items[i];
                            final imageUrl = SupabaseConstants.imageUrl(item.productImage);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
                              ),
                              child: Row(
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (ctx, url, err) => Container(
                                                color: AppColors.background,
                                                child: const Icon(Icons.medication, color: AppColors.divider),
                                              ),
                                            )
                                          : Container(
                                              color: AppColors.background,
                                              child: const Icon(Icons.medication, color: AppColors.divider),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productTitle,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                                            maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('GHS ${item.productPrice.toStringAsFixed(2)} each',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            // Qty controls
                                            _qtyButton(Icons.remove, () {
                                              if (item.qty > 1) {
                                                cart.updateItem(item.productId, item.qty - 1);
                                              } else {
                                                cart.removeItem(item.productId);
                                              }
                                            }),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                            ),
                                            _qtyButton(Icons.add, () {
                                              if (item.qty < item.productStock) {
                                                cart.updateItem(item.productId, item.qty + 1);
                                              }
                                            }),
                                            const Spacer(),
                                            Text('GHS ${item.lineTotal.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                                          ],
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
                    ),

                    // ── Summary + Checkout ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, -2))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${cart.itemCount} item${cart.itemCount != 1 ? 's' : ''}',
                                  style: const TextStyle(color: AppColors.textSecondary)),
                              Text('GHS ${cart.cartTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AppButton(
                            label: 'Proceed to Checkout',
                            onPressed: () => Navigator.pushNamed(context, '/checkout'),
                            icon: Icons.arrow_forward,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}

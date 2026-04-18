import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _addressCtrl  = TextEditingController();
  final _cityCtrl     = TextEditingController();
  final _contactCtrl  = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final orders = context.read<OrderProvider>();
    final result = await orders.createOrder(
      address: _addressCtrl.text.trim(),
      city:    _cityCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
    );

    if (!mounted) return;

    if (result != null) {
      context.read<CartProvider>().clearLocalCart();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Order Placed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Invoice #${result['invoice_no']}', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text('${result['item_count']} item(s) • Status: ${result['status']}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, '/main');
              },
              child: const Text('View Orders'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orders.error ?? 'Failed to place order.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart     = context.watch<CartProvider>();
    final isLoading = context.watch<OrderProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order summary ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...cart.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${item.productTitle} x${item.qty}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                              Text('GHS ${item.lineTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('GHS ${cart.cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Delivery details ────────────────────────────────────────
              const Text('Delivery Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Delivery Address',
                controller: _addressCtrl,
                prefixIcon: Icons.home_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required.' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'City',
                controller: _cityCtrl,
                prefixIcon: Icons.location_city_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required.' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Phone Number',
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required.' : null,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Place Order',
                onPressed: _placeOrder,
                isLoading: isLoading,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum _PayMethod { paystack, cashOnDelivery }

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _addressCtrl  = TextEditingController();
  final _cityCtrl     = TextEditingController();
  final _contactCtrl  = TextEditingController();

  _PayMethod _payMethod = _PayMethod.paystack;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;
    if (_payMethod == _PayMethod.paystack) {
      await _payWithPaystack();
    } else {
      await _placeOrder(isPaid: false);
    }
  }

  Future<void> _payWithPaystack() async {
    final auth  = context.read<AuthProvider>();
    final cart  = context.read<CartProvider>();
    final email = auth.customerEmail ?? '';
    final total = cart.cartTotal;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email not found.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final reference = 'PV-${DateTime.now().millisecondsSinceEpoch}';
    bool paymentSucceeded = false;

    if (!mounted) return;

    await FlutterPaystackPlus.openPaystackPopup(
      context:       context,
      secretKey:     SupabaseConstants.paystackSecretKey,
      customerEmail: email,
      reference:     reference,
      amount:        ((total * 100).toInt()).toString(),
      currency:      'GHS',
      onClosed: () {
        if (!paymentSucceeded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled.'), backgroundColor: AppColors.error),
          );
        }
      },
      onSuccess: () async {
        paymentSucceeded = true;
        await _placeOrder(
          isPaid:           true,
          paymentAmount:    total,
          paymentReference: reference,
        );
      },
    );
  }

  Future<void> _placeOrder({
    required bool isPaid,
    double paymentAmount = 0.0,
    String? paymentReference,
  }) async {
    final orders = context.read<OrderProvider>();
    final result = await orders.createOrder(
      address:          _addressCtrl.text.trim(),
      city:             _cityCtrl.text.trim(),
      contact:          _contactCtrl.text.trim(),
      isPaid:           isPaid,
      paymentAmount:    paymentAmount,
      paymentReference: paymentReference,
    );

    if (!mounted) return;

    if (result != null) {
      context.read<CartProvider>().clearLocalCart();
      await _showSuccess(result, isPaid: isPaid, reference: paymentReference);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orders.error ?? 'Failed to place order.'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _showSuccess(
    Map<String, dynamic> result, {
    required bool isPaid,
    String? reference,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPaid ? AppColors.success : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaid ? Icons.verified_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white, size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPaid ? 'Payment Successful!' : 'Order Placed!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Invoice #${result['invoice_no']}',
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${result['item_count']} item(s)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (isPaid && reference != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Ref: $reference',
                    style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Pay on Delivery',
                    style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/main');
            },
            child: const Text('View Orders', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart      = context.watch<CartProvider>();
    final isLoading = context.watch<OrderProvider>().isLoading;
    final total     = cart.cartTotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order summary ────────────────────────────────────────────
              _card(
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
                              Expanded(
                                child: Text('${item.productTitle} ×${item.qty}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('GHS ${item.lineTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('GHS ${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Delivery details ─────────────────────────────────────────
              const Text('Delivery Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Delivery Address',
                controller: _addressCtrl,
                prefixIcon: Icons.home_outlined,
                inputFormatters: AppFormatters.address,
                validator: AppValidators.address,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'City',
                controller: _cityCtrl,
                prefixIcon: Icons.location_city_outlined,
                inputFormatters: AppFormatters.city,
                validator: AppValidators.city,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Phone Number',
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                inputFormatters: AppFormatters.phone,
                validator: AppValidators.phone,
              ),
              const SizedBox(height: 22),

              // ── Payment method ───────────────────────────────────────────
              const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _PayMethodTile(
                value: _PayMethod.paystack,
                groupValue: _payMethod,
                icon: Icons.credit_card_rounded,
                label: 'Pay with Card',
                sublabel: 'Visa, Mastercard, Bank Transfer via Paystack',
                onChanged: (v) => setState(() => _payMethod = v!),
              ),
              const SizedBox(height: 10),
              _PayMethodTile(
                value: _PayMethod.cashOnDelivery,
                groupValue: _payMethod,
                icon: Icons.payments_outlined,
                label: 'Cash on Delivery',
                sublabel: 'Pay when your order arrives',
                onChanged: (v) => setState(() => _payMethod = v!),
              ),
              const SizedBox(height: 28),

              AppButton(
                label: _payMethod == _PayMethod.paystack
                    ? 'Pay GHS ${total.toStringAsFixed(2)}'
                    : 'Place Order',
                onPressed: _proceed,
                isLoading: isLoading,
                icon: _payMethod == _PayMethod.paystack
                    ? Icons.lock_outline_rounded
                    : Icons.check_circle_outline,
              ),
              if (_payMethod == _PayMethod.paystack) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Secured by Paystack',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
        ),
        child: child,
      );
}

// ── Payment method tile ──────────────────────────────────────────────────────

class _PayMethodTile extends StatelessWidget {
  final _PayMethod value;
  final _PayMethod groupValue;
  final IconData icon;
  final String label;
  final String sublabel;
  final ValueChanged<_PayMethod?> onChanged;

  const _PayMethodTile({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE8E8E8),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(sublabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFCCCCCC),
                  width: selected ? 5 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/ghana_cities.dart';
import '../../constants/supabase_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

enum _PayMethod { card, momo }

// Greater Accra cities — GHS 30 delivery, all others GHS 50
const _kGreaterAccraCities = {
  'Accra', 'Ashaiman', 'Dome', 'Kasoa', 'Madina', 'Tema',
};

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  _PayMethod _payMethod      = _PayMethod.card;
  String?    _selectedCity;
  bool       _loadingAddresses = false;
  bool       _gpsLoading       = false;
  List<Map<String, dynamic>> _savedAddresses = [];

  double get _deliveryFee {
    if (_selectedCity == null) return 0.0;
    return _kGreaterAccraCities.contains(_selectedCity) ? 30.0 : 50.0;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (_contactCtrl.text.isEmpty && auth.customerContact != null) {
        _contactCtrl.text = auth.customerContact!;
      }
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final data = await Supabase.instance.client
            .from('user_addresses')
            .select()
            .eq('user_id', uid)
            .order('created_at');
        if (mounted) {
          setState(() => _savedAddresses = List<Map<String, dynamic>>.from(data));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAddresses = false);
  }

  void _pickSavedAddress() {
    if (_savedAddresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved addresses. Add one in your profile.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Saved Addresses',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          ..._savedAddresses.map((addr) {
            final icon = addr['icon_type'] == 'office'
                ? Icons.business_rounded
                : addr['icon_type'] == 'other'
                    ? Icons.location_on_rounded
                    : Icons.home_rounded;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              title: Text(addr['label'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(addr['address'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              onTap: () {
                _addressCtrl.text = addr['address'] ?? '';
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _useGpsLocation() async {
    setState(() => _gpsLoading = true);
    try {
      final location = context.read<LocationProvider>();
      await location.fetchLocation();
      if (!mounted) return;
      final city = location.cityName;
      // Try exact match first, then partial match
      String? match;
      for (final c in kGhanaCities) {
        if (c.toLowerCase() == city.toLowerCase()) { match = c; break; }
      }
      match ??= kGhanaCities.where(
        (c) => city.toLowerCase().contains(c.toLowerCase()) ||
               c.toLowerCase().contains(city.toLowerCase()),
      ).firstOrNull;

      if (match != null) {
        setState(() => _selectedCity = match);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected "$city" — please select your city manually.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please select city manually.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _gpsLoading = false);
  }

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your city.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await _payWithPaystack();
  }

  Future<void> _payWithPaystack() async {
    final auth      = context.read<AuthProvider>();
    final cart      = context.read<CartProvider>();
    final email     = auth.customerEmail ?? '';
    final grandTotal = cart.cartTotal + _deliveryFee;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email not found.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final reference      = 'PV-${DateTime.now().millisecondsSinceEpoch}';
    bool paymentSucceeded = false;

    if (!mounted) return;

    await FlutterPaystackPlus.openPaystackPopup(
      context:       context,
      secretKey:     SupabaseConstants.paystackSecretKey,
      customerEmail: email,
      reference:     reference,
      amount:        ((grandTotal * 100).toInt()).toString(),
      currency:      'GHS',
      onClosed: () {
        if (!paymentSucceeded && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      onSuccess: () async {
        paymentSucceeded = true;
        await _placeOrder(
          isPaid:           true,
          paymentAmount:    grandTotal,
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
    final cart   = context.read<CartProvider>();
    final result = await orders.createOrder(
      address:          _addressCtrl.text.trim(),
      city:             _selectedCity!,
      contact:          _contactCtrl.text.trim(),
      deliveryFee:      _deliveryFee,
      isPaid:           isPaid,
      paymentAmount:    paymentAmount,
      paymentReference: paymentReference,
    );

    if (!mounted) return;

    if (result != null) {
      cart.clearLocalCart();
      await _showSuccess(result, isPaid: isPaid, reference: paymentReference);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orders.error ?? 'Failed to place order.'),
          backgroundColor: AppColors.error,
        ),
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
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Order Placed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Invoice #${result['invoice_no']}',
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${result['item_count']} item(s)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isPaid ? 'Paid · Ref: $reference' : 'Payment Confirmed',
                style: const TextStyle(
                  color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/main');
            },
            child: const Text('View Orders',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart       = context.watch<CartProvider>();
    final isLoading  = context.watch<OrderProvider>().isLoading;
    final itemsTotal = cart.cartTotal;
    final grandTotal = itemsTotal + _deliveryFee;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Order Summary ──────────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...cart.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${item.productTitle} ×${item.qty}',
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('GHS ${item.lineTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(height: 20),
                    _summaryRow('Subtotal', 'GHS ${itemsTotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    _summaryRow(
                      'Delivery Fee',
                      _selectedCity == null
                          ? 'Select city'
                          : 'GHS ${_deliveryFee.toStringAsFixed(2)}',
                      valueColor: _selectedCity == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(
                          'GHS ${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                    if (_selectedCity != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _kGreaterAccraCities.contains(_selectedCity)
                                ? 'Greater Accra delivery — GHS 30'
                                : 'Outside Greater Accra — GHS 50',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Delivery Details ───────────────────────────────────────────
              const Text('Delivery Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),

              // Address field + saved picker button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Delivery Address',
                      controller: _addressCtrl,
                      prefixIcon: Icons.home_outlined,
                      inputFormatters: AppFormatters.address,
                      validator: AppValidators.address,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _loadingAddresses
                      ? const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary)),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _IconActionButton(
                            icon: Icons.bookmark_outline_rounded,
                            tooltip: 'Saved addresses',
                            onTap: _pickSavedAddress,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 14),

              // City dropdown + GPS button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(
                          Icons.location_city_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.error)),
                        filled: true,
                        fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                            (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1F2937)
                                : Colors.white),
                        labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      items: kGhanaCities
                          .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(city,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCity = v),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please select your city.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _gpsLoading
                        ? const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary)),
                            ))
                        : _IconActionButton(
                            icon: Icons.my_location_rounded,
                            tooltip: 'Use GPS location',
                            onTap: _useGpsLocation,
                          ),
                  ),
                ],
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

              // ── Payment Method ─────────────────────────────────────────────
              const Text('Payment Method',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              _PayMethodTile(
                value: _PayMethod.card,
                groupValue: _payMethod,
                icon: Icons.credit_card_rounded,
                label: 'Pay with Card',
                sublabel: 'Visa, Mastercard, Bank Transfer via Paystack',
                onChanged: (v) => setState(() => _payMethod = v!),
              ),
              const SizedBox(height: 10),
              _PayMethodTile(
                value: _PayMethod.momo,
                groupValue: _payMethod,
                icon: Icons.phone_android_rounded,
                label: 'Mobile Money (MoMo)',
                sublabel: 'MTN, Vodafone, AirtelTigo via Paystack',
                onChanged: (v) => setState(() => _payMethod = v!),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Both options open the secure Paystack checkout — you can choose Card or MoMo (MTN, Vodafone, AirtelTigo) inside the popup.',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary.withAlpha(200),
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                label: 'Pay GHS ${grandTotal.toStringAsFixed(2)}',
                onPressed: _proceed,
                isLoading: isLoading,
                icon: Icons.lock_outline_rounded,
              ),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
        ),
        child: child,
      );

  Widget _summaryRow(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      );
}

// ── Small GPS / bookmark icon button ────────────────────────────────────────

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconActionButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryLight : Theme.of(context).dividerColor.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: selected
                              ? Theme.of(context).colorScheme.onSurface
                              : AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
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

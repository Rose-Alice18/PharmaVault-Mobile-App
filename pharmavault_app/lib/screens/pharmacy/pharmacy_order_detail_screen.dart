import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';

class PharmacyOrderDetailScreen extends StatefulWidget {
  const PharmacyOrderDetailScreen({super.key});

  @override
  State<PharmacyOrderDetailScreen> createState() => _PharmacyOrderDetailScreenState();
}

class _PharmacyOrderDetailScreenState extends State<PharmacyOrderDetailScreen> {
  final _db = SupabaseConstants.client;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  static const _statuses = ['pending', 'confirmed', 'processing', 'dispatched', 'delivered', 'cancelled'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orderId = ModalRoute.of(context)!.settings.arguments as int;
    _fetch(orderId);
  }

  Future<void> _fetch(int orderId) async {
    setState(() => _loading = true);
    try {
      final orderData = await _db
          .from('orders')
          .select('*, profiles(customer_name, customer_contact, customer_email, customer_city)')
          .eq('order_id', orderId)
          .single();
      final itemsData = await _db
          .from('order_items')
          .select('*, products(product_title, product_image, product_price)')
          .eq('order_id', orderId);
      setState(() {
        _order = orderData;
        _items = List<Map<String, dynamic>>.from(itemsData as List);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_order == null) return;
    try {
      await _db
          .from('orders')
          .update({'order_status': newStatus})
          .eq('order_id', _order!['order_id'] as int);
      setState(() => _order!['order_status'] = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: AppColors.primary,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showStatusPicker() {
    if (_order == null) return;
    final currentStatus = _order!['order_status'] as String? ?? 'pending';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            const Text('Update Order Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 14),
            ..._statuses.map((s) {
              final isCurrent = s == currentStatus;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCurrent ? _statusColor(s).withAlpha(20) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_statusIcon(s), color: isCurrent ? _statusColor(s) : AppColors.textSecondary, size: 20),
                ),
                title: Text(
                  s[0].toUpperCase() + s.substring(1),
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? _statusColor(s) : AppColors.textPrimary,
                  ),
                ),
                trailing: isCurrent ? Icon(Icons.check_circle_rounded, color: _statusColor(s)) : null,
                onTap: isCurrent ? null : () {
                  Navigator.pop(ctx);
                  _updateStatus(s);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'pending'    => AppColors.warning,
    'confirmed'  => AppColors.primary,
    'processing' => const Color(0xFF7C3AED),
    'dispatched' => const Color(0xFF0891B2),
    'delivered'  => AppColors.success,
    'cancelled'  => AppColors.error,
    _            => AppColors.textSecondary,
  };

  IconData _statusIcon(String s) => switch (s) {
    'pending'    => Icons.hourglass_empty_rounded,
    'confirmed'  => Icons.check_circle_outline_rounded,
    'processing' => Icons.inventory_2_outlined,
    'dispatched' => Icons.local_shipping_outlined,
    'delivered'  => Icons.home_outlined,
    'cancelled'  => Icons.cancel_outlined,
    _            => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details'), backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0, surfaceTintColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details'), backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0, surfaceTintColor: Colors.white),
        body: const Center(child: Text('Order not found.')),
      );
    }

    final o       = _order!;
    final profile = o['profiles'] as Map<String, dynamic>? ?? {};
    final status  = o['order_status'] as String? ?? 'pending';
    final total   = double.tryParse(o['order_total'].toString()) ?? 0.0;
    Map<String, dynamic> delivery = {};
    if (o['delivery_notes'] != null) {
      try { delivery = jsonDecode(o['delivery_notes'] as String) as Map<String, dynamic>; } catch (_) {}
    }
    String dateStr = '';
    try { dateStr = DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(o['order_date'] as String)); } catch (_) {}

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Invoice #${o['invoice_no']}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: ElevatedButton.icon(
          onPressed: _showStatusPicker,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text('Update Status  •  ${status[0].toUpperCase()}${status.substring(1)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _statusColor(status),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + date
            _card(child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: _statusColor(status)),
                      const SizedBox(width: 6),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (o['is_paid'] == true ? AppColors.success : AppColors.warning).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        o['is_paid'] == true ? 'Paid' : 'Unpaid',
                        style: TextStyle(
                          color: o['is_paid'] == true ? AppColors.success : AppColors.warning,
                          fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 12),

            // Customer info
            _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                _infoRow(Icons.person_outline, profile['customer_name'] as String? ?? '-'),
                const SizedBox(height: 6),
                _infoRow(Icons.phone_outlined, profile['customer_contact'] as String? ?? '-'),
                if (profile['customer_email'] != null) ...[
                  const SizedBox(height: 6),
                  _infoRow(Icons.email_outlined, profile['customer_email'] as String),
                ],
              ],
            )),
            const SizedBox(height: 12),

            // Delivery address
            if (delivery.isNotEmpty) ...[
              _card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.home_outlined, delivery['address'] as String? ?? '-'),
                  const SizedBox(height: 6),
                  _infoRow(Icons.location_city_outlined, delivery['city'] as String? ?? '-'),
                  const SizedBox(height: 6),
                  _infoRow(Icons.phone_outlined, delivery['contact'] as String? ?? '-'),
                ],
              )),
              const SizedBox(height: 12),
            ],

            // Items
            _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                ..._items.map((item) {
                  final product  = item['products'] as Map<String, dynamic>? ?? {};
                  final imageUrl = SupabaseConstants.imageUrl(product['product_image'] as String? ?? '');
                  final price    = double.tryParse(item['item_price'].toString()) ?? 0.0;
                  final qty      = item['item_qty'] as int? ?? 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 52, height: 52,
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover,
                                    errorWidget: (ctx, url, err) => Container(color: AppColors.background,
                                        child: const Icon(Icons.medication, color: AppColors.divider)))
                                : Container(color: AppColors.background,
                                    child: const Icon(Icons.medication, color: AppColors.divider)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['product_title'] as String? ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('GHS ${price.toStringAsFixed(2)} × $qty',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('GHS ${(price * qty).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('GHS ${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
    ),
    child: child,
  );

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
    ],
  );
}

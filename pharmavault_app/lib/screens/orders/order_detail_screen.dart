import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final id = ModalRoute.of(context)!.settings.arguments as int;
      context.read<OrderProvider>().fetchOrderById(id);
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending'   => AppColors.warning,
      'confirmed' => AppColors.primary,
      'delivered' => AppColors.success,
      'cancelled' => AppColors.error,
      _           => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();

    if (op.isLoading || op.selectedOrder == null) {
      return Scaffold(appBar: AppBar(title: const Text('Order Details')), body: const Center(child: CircularProgressIndicator()));
    }

    final order = op.selectedOrder!;
    final items = op.selectedItems;

    String dateStr = '';
    try { dateStr = DateFormat('d MMM yyyy').format(DateTime.parse(order.orderDate)); }
    catch (_) { dateStr = order.orderDate; }

    // Parse delivery notes JSON
    Map<String, dynamic> delivery = {};
    if (order.deliveryNotes != null) {
      try { delivery = jsonDecode(order.deliveryNotes!) as Map<String, dynamic>; }
      catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Invoice #${order.invoiceNo}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Status card ─────────────────────────────────────────────
            _card(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(order.orderStatus).withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(order.orderStatus.toUpperCase(),
                        style: TextStyle(color: _statusColor(order.orderStatus), fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(order.isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(color: order.isPaid ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Delivery info ────────────────────────────────────────────
            if (delivery.isNotEmpty)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    _infoRow(Icons.home_outlined,   delivery['address'] as String? ?? ''),
                    const SizedBox(height: 6),
                    _infoRow(Icons.location_city,   delivery['city']    as String? ?? ''),
                    const SizedBox(height: 6),
                    _infoRow(Icons.phone_outlined,  delivery['contact'] as String? ?? ''),
                  ],
                ),
              ),
            if (delivery.isNotEmpty) const SizedBox(height: 12),

            // ── Items ────────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  ...items.map((item) {
                    final url = SupabaseConstants.imageUrl(item.productImage);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 56, height: 56,
                              child: url.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                                      errorWidget: (ctx, url, err) => Container(color: AppColors.background, child: const Icon(Icons.medication, color: AppColors.divider)))
                                  : Container(color: AppColors.background, child: const Icon(Icons.medication, color: AppColors.divider)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text('GHS ${item.productPrice.toStringAsFixed(2)} × ${item.qty}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('GHS ${item.lineTotal.toStringAsFixed(2)}',
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
                      Text('GHS ${op.selectedTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
      ],
    );
  }
}

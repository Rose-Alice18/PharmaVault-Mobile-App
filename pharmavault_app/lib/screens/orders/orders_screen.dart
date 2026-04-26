import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_state.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _activeStatuses  = {'pending', 'confirmed', 'processing'};
  static const _pastStatuses    = {'delivered', 'cancelled'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending'    => AppColors.warning,
      'confirmed'  => AppColors.secondary,
      'processing' => AppColors.primary,
      'delivered'  => AppColors.success,
      'cancelled'  => AppColors.error,
      _            => AppColors.textSecondary,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending'    => 'Pending',
      'confirmed'  => 'Confirmed',
      'processing' => 'On the way',
      'delivered'  => 'Delivered',
      'cancelled'  => 'Cancelled',
      _            => status,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'pending'    => Icons.schedule_rounded,
      'confirmed'  => Icons.check_circle_outline_rounded,
      'processing' => Icons.local_shipping_rounded,
      'delivered'  => Icons.check_circle_rounded,
      'cancelled'  => Icons.cancel_rounded,
      _            => Icons.receipt_long_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    final active = op.orders.where((o) => _activeStatuses.contains(o.orderStatus)).toList();
    final past   = op.orders.where((o) => _pastStatuses.contains(o.orderStatus)).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha(160),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (active.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                      child: Text('${active.length}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Past'),
                  if (past.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(10)),
                      child: Text('${past.length}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: op.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _OrderList(orders: active, onRefresh: () => op.fetchOrders(), statusColor: _statusColor, statusLabel: _statusLabel, statusIcon: _statusIcon,
                    emptyIcon: Icons.shopping_bag_outlined, emptyTitle: 'No active orders', emptySubtitle: 'Your active orders will appear here.'),
                _OrderList(orders: past, onRefresh: () => op.fetchOrders(), statusColor: _statusColor, statusLabel: _statusLabel, statusIcon: _statusIcon,
                    emptyIcon: Icons.receipt_long_outlined, emptyTitle: 'No past orders', emptySubtitle: 'Completed and cancelled orders will appear here.'),
              ],
            ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final Future<void> Function() onRefresh;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final IconData Function(String) statusIcon;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _OrderList({
    required this.orders,
    required this.onRefresh,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return EmptyState(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final order = orders[i];
          String dateStr = '';
          try {
            final dt = DateTime.parse(order.orderDate);
            dateStr = DateFormat('d MMM yyyy, h:mm a').format(dt);
          } catch (_) {
            dateStr = order.orderDate;
          }
          final color = statusColor(order.orderStatus);

          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/order-detail', arguments: order.orderId),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
              ),
              child: Column(
                children: [
                  // Top row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(statusIcon(order.orderStatus), color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.invoiceNo,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(dateStr, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(140), fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel(order.orderStatus),
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  // Bottom row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Row(
                      children: [
                        Icon(Icons.local_pharmacy_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withAlpha(140)),
                        const SizedBox(width: 4),
                        Text('PharmaVault', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(140))),
                        const Spacer(),
                        Text(
                          'GHS ${order.orderTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withAlpha(120), size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

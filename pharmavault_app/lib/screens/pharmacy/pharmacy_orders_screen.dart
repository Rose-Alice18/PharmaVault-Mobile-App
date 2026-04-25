import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/supabase_constants.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen> {
  final _db          = SupabaseConstants.client;
  final _searchCtrl  = TextEditingController();
  List<Map<String, dynamic>> _orders   = [];
  List<Map<String, dynamic>> _filtered = [];
  bool    _loading      = true;
  String? _error;
  String  _statusFilter = 'all';

  static const _filterStatuses = ['all', 'pending', 'confirmed', 'processing', 'dispatched', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _db
          .from('orders')
          .select('order_id, invoice_no, order_date, order_status, order_total, is_paid, profiles(customer_name, customer_contact)')
          .order('order_date', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data as List);
        _applyFilter();
        _loading = false;
      });
    } catch (_) {
      setState(() { _error = 'Failed to load orders.'; _loading = false; });
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase().trim();
    _filtered = _orders.where((o) {
      final profile     = o['profiles'] as Map<String, dynamic>? ?? {};
      final status      = o['order_status'] as String? ?? '';
      final invoiceNo   = (o['invoice_no'] as String? ?? '').toLowerCase();
      final customerName = (profile['customer_name'] as String? ?? '').toLowerCase();

      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
      final matchesSearch = query.isEmpty ||
          invoiceNo.contains(query) ||
          customerName.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
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
    final pending = _orders.where((o) => o['order_status'] == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Manage Orders'),
            if (pending > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchOrders),
        ],
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(_applyFilter),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by invoice or customer...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () => setState(() { _searchCtrl.clear(); _applyFilter(); }),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // Status filter chips
          Container(
            color: Colors.white,
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filterStatuses.length,
              itemBuilder: (context, i) {
                final s        = _filterStatuses[i];
                final selected = _statusFilter == s;
                final count    = s == 'all' ? _orders.length : _orders.where((o) => o['order_status'] == s).length;
                return GestureDetector(
                  onTap: () => setState(() { _statusFilter = s; _applyFilter(); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1)} ($count)',
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(color: const Color(0xFFF4F6F5), borderRadius: BorderRadius.circular(20)),
                                child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchCtrl.text.isNotEmpty || _statusFilter != 'all'
                                    ? 'No matching orders'
                                    : 'No orders yet',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              const Text('Orders placed by customers will appear here',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ]),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchOrders,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final o       = _filtered[i];
                                final profile = o['profiles'] as Map<String, dynamic>? ?? {};
                                final status  = o['order_status'] as String? ?? 'pending';
                                final total   = double.tryParse(o['order_total'].toString()) ?? 0.0;
                                String dateStr = '';
                                try {
                                  dateStr = DateFormat('d MMM yyyy').format(DateTime.parse(o['order_date'] as String));
                                } catch (_) {}

                                return GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/pharmacy-order-detail',
                                    arguments: o['order_id'] as int,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: status == 'pending'
                                          ? Border.all(color: AppColors.warning.withAlpha(80), width: 1.5)
                                          : null,
                                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(o['invoice_no'].toString(),
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withAlpha(20),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(_statusIcon(status), size: 11, color: _statusColor(status)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    status[0].toUpperCase() + status.substring(1),
                                                    style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w700),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(profile['customer_name'] as String? ?? 'Customer',
                                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                        ]),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(profile['customer_contact'] as String? ?? '',
                                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                        ]),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            Row(children: [
                                              Text('GHS ${total.toStringAsFixed(2)}',
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (o['is_paid'] == true ? AppColors.success : AppColors.warning).withAlpha(20),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  o['is_paid'] == true ? 'Paid' : 'Unpaid',
                                                  style: TextStyle(
                                                    fontSize: 10, fontWeight: FontWeight.w700,
                                                    color: o['is_paid'] == true ? AppColors.success : AppColors.warning,
                                                  ),
                                                ),
                                              ),
                                            ]),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 2),
                                          const Text('Tap to view details',
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

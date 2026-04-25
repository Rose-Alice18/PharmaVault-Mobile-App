import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';

class NotifItem {
  final String  title;
  final String  body;
  final DateTime time;
  final String  type;
  bool isRead;

  NotifItem({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class NotificationProvider extends ChangeNotifier {
  final List<NotifItem> _items = [];
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _prescriptionsChannel;

  List<NotifItem> get items       => List.unmodifiable(_items);
  int             get unreadCount => _items.where((n) => !n.isRead).length;

  void subscribe(String userId) {
    _unsubscribe();

    // Listen for order status changes
    _ordersChannel = Supabase.instance.client
        .channel('orders_notif_$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'orders',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'c_id',
            value:  userId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['order_status'] as String? ?? '';
            final oldStatus = payload.oldRecord['order_status'] as String? ?? '';
            final invoiceNo = payload.newRecord['invoice_no']   as String? ?? '';
            if (newStatus == oldStatus) return;
            _addItem(NotifItem(
              title: NotificationService.orderStatusTitle(newStatus),
              body:  'Your order $invoiceNo status updated to $newStatus.',
              time:  DateTime.now(),
              type:  'order',
            ));
            NotificationService.showOrderUpdate(invoiceNo: invoiceNo, status: newStatus);
          },
        )
        .subscribe();

    // Listen for prescription status changes
    _prescriptionsChannel = Supabase.instance.client
        .channel('prescriptions_notif_$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'prescriptions',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'c_id',
            value:  userId,
          ),
          callback: (payload) {
            final status = payload.newRecord['status'] as String? ?? '';
            _addItem(NotifItem(
              title: 'Prescription Update',
              body:  'Your prescription has been $status.',
              time:  DateTime.now(),
              type:  'prescription',
            ));
            NotificationService.showPrescriptionUpdate(status: status);
          },
        )
        .subscribe();
  }

  void _addItem(NotifItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _items) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void _unsubscribe() {
    _ordersChannel?.unsubscribe();
    _prescriptionsChannel?.unsubscribe();
    _ordersChannel = null;
    _prescriptionsChannel = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}

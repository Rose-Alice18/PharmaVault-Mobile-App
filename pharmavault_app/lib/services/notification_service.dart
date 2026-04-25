import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId   = 'pharmavault_notifications';
  static const _channelName = 'PharmaVault Notifications';

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings    = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Request permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Create notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Order and prescription updates from PharmaVault',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showOrderPlaced({required String invoiceNo}) async {
    await _show(
      id:    invoiceNo.hashCode,
      title: 'Order Placed!',
      body:  'Your order $invoiceNo has been received and is being processed.',
    );
  }

  static Future<void> showOrderUpdate({
    required String invoiceNo,
    required String status,
  }) async {
    final message = switch (status.toLowerCase()) {
      'confirmed'  => 'Your order $invoiceNo has been confirmed.',
      'processing' => 'Your order $invoiceNo is being prepared.',
      'dispatched' => 'Your order $invoiceNo is out for delivery!',
      'delivered'  => 'Your order $invoiceNo has been delivered. Enjoy!',
      'cancelled'  => 'Your order $invoiceNo was cancelled.',
      _            => 'Your order $invoiceNo status updated to $status.',
    };
    await _show(
      id:    invoiceNo.hashCode,
      title: _statusTitle(status),
      body:  message,
    );
  }

  static Future<void> showPrescriptionUpdate({required String status}) async {
    final body = switch (status.toLowerCase()) {
      'verified' => 'Your prescription has been verified. You can now order your medicines.',
      'rejected' => 'Your prescription was rejected. Please upload a valid prescription.',
      'expired'  => 'Your prescription has expired. Please upload a new one.',
      _          => 'Your prescription status has been updated to $status.',
    };
    await _show(
      id:    status.hashCode,
      title: 'Prescription Update',
      body:  body,
    );
  }

  static Future<void> _show({
    required int    id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority:   Priority.high,
      icon:       '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  static String orderStatusTitle(String status) => _statusTitle(status);

  static String _statusTitle(String status) {
    return switch (status.toLowerCase()) {
      'confirmed'  => 'Order Confirmed',
      'processing' => 'Order Being Prepared',
      'dispatched' => 'Order On the Way',
      'delivered'  => 'Order Delivered',
      'cancelled'  => 'Order Cancelled',
      _            => 'Order Update',
    };
  }
}

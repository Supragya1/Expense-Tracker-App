import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

/// Notification Service - Shows transaction alerts and handles taps
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  /// Initialize notification system
  Future<void> init() async {
    // Android initialization
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'finance_alerts',
      'Finance Alerts',
      description: 'Transaction notifications from Road Ronin Finance',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show transaction notification
  Future<void> showTransactionNotification({
    required double amount,
    required String bankName,
    required String type,
    required String receiverName,
    required String payload,
  }) async {
    final isCredit = type == 'CREDIT';
    final title = isCredit
        ? '₹${amount.toStringAsFixed(0)} Received'
        : '₹${amount.toStringAsFixed(0)} Spent';
    final body =
        '${isCredit ? "From" : "To"} $receiverName via $bankName. Tap to add details.';

    final androidDetails = AndroidNotificationDetails(
      'finance_alerts',
      'Finance Alerts',
      channelDescription: 'Transaction notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF4CAF50),
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap - navigate to Add Transaction screen
  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;

    // Parse payload: "amount|bank|type|receiver|balance|timestamp"
    final parts = response.payload!.split('|');
    if (parts.length < 5) return;

    final args = {
      'amount': parts[0],
      'bankName': parts[1],
      'type': parts[2],
      'receiverName': parts[3],
      'balance': parts[4],
      'timestamp': parts.length > 5
          ? parts[5]
          : DateTime.now().millisecondsSinceEpoch.toString(),
      'fromNotification': true,
    };

    // Navigate using global navigator key
    navigatorKey.currentState?.pushNamed(
      '/add_transaction',
      arguments: args,
    );
  }
}

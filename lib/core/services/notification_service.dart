import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:sparix/config/firebase_options.dart';
import 'package:sparix/presentation/screens/spare_parts/spare_part_details_page.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'default_channel',
    'Default Notifications',
    description: 'This channel is used for default notifications.',
    importance: Importance.high,
  );

  static late GlobalKey<NavigatorState> _navKey;

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navKey = navigatorKey;

    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: initAndroid);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
      onDidReceiveBackgroundNotificationResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.subscribeToTopic('lowStockTopic');

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageDeepLink);

    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      _handleMessageDeepLink(initialMsg);
    }
  }

  static Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    debugPrint('📩 onMessage data=${message.data} notif=${message.notification?.title}');
    final n = message.notification;
    final data = message.data;

    final title = n?.title ?? data['title'] ?? 'Notification';
    final body  = n?.body  ?? data['body']  ?? '';

    final payloadMap = <String, dynamic>{
      'route':     data['route'] ?? 'spare_part_detail',
      'productId': data['productId'],
    };

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          channelDescription: 'This channel is used for default notifications.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(payloadMap),
    );
    debugPrint('showed local notification id=$id');
  }

  static void _handleMessageDeepLink(RemoteMessage message) {
    final data = message.data;
    final route = (data['route'] ?? 'spare_part_detail').toString();
    final productId = (data['productId'] ?? '').toString();

    if (route == 'spare_part_detail' && productId.isNotEmpty) {
      _navigateToProduct(productId);
    } else {
      debugPrint('Notification data (no navigation): $data');
    }
  }

  static void _onLocalNotificationTap(NotificationResponse resp) {
    final raw = resp.payload;
    if (raw == null || raw.isEmpty) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final route = (map['route'] ?? '').toString();
      final productId = (map['productId'] ?? '').toString();

      if (route == 'spare_part_detail' && productId.isNotEmpty) {
        _navigateToProduct(productId);
      }
    } catch (e) {
      debugPrint('Failed to parse notification payload: $e');
    }
  }

  static void _navigateToProduct(String productId) {
    final ctx = _navKey.currentContext;
    if (ctx == null) return;

    _navKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => SparePartDetailsPage(productId: productId),
      ),
    );
  }

  static Future<void> showTestLocal({String productId = 'TEST-123'}) async {
    final payload = jsonEncode({
      'route': 'spare_part_detail',
      'productId': productId,
    });

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Test Local Notification',
      'Tap to open SparePartDetails',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          channelDescription: 'This channel is used for default notifications.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  final data  = message.data;
  final title = message.notification?.title ?? data['title'] ?? 'Notification';
  final body  = message.notification?.body  ?? data['body']  ?? '';

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
    'default_channel',
    'Default Notifications',
    description: 'This channel is used for default notifications.',
    importance: Importance.high,
  ));

  final payloadMap = <String, dynamic>{
    'route':     data['route'] ?? 'spare_part_detail',
    'productId': data['productId'],
  };

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'This channel is used for default notifications.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: jsonEncode(payloadMap),
  );
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse resp) {
}

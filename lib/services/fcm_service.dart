import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../models/order_model.dart';
import '../screens/order_details_screen.dart';

class FCMService {
  FCMService._();

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'jamboo_notifications',
    'Jamboo Notifications',
    description: 'Order updates and important notifications',
    importance: Importance.high,
  );

  static StreamSubscription<RemoteMessage>?
      _foregroundSubscription;

  static StreamSubscription<RemoteMessage>?
      _notificationTapSubscription;

  static bool _initialized = false;
  static bool _navigationInProgress = false;

  static String? _pendingOrderId;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) {
      return;
    }

    final FirebaseMessaging messaging =
        FirebaseMessaging.instance;

    final NotificationSettings settings =
        await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'Notification Permission: '
      '${settings.authorizationStatus}',
    );

    // FCM TOKEN
    try {
      final token = await messaging.getToken();

      debugPrint('FCM TOKEN: $token');
    } catch (e) {
      debugPrint('FCM Token Error: $e');
    }

    // ANDROID NOTIFICATION CHANNEL
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // LOCAL NOTIFICATION INITIALIZATION
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          _onLocalNotificationTap,
    );

    // FOREGROUND NOTIFICATIONS
    await _foregroundSubscription?.cancel();

    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );

    // BACKGROUND NOTIFICATION TAP
    await _notificationTapSubscription?.cancel();

    _notificationTapSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(
      _onRemoteNotificationTap,
    );

    // APP OPENED FROM TERMINATED STATE
    final RemoteMessage? initialMessage =
        await messaging.getInitialMessage();

    if (initialMessage != null) {
      _onRemoteNotificationTap(initialMessage);
    }

    // TOKEN REFRESH
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        debugPrint('New FCM Token: $newToken');
      },
    );

    _initialized = true;
  }

  // ============================================================
  // FOREGROUND NOTIFICATION
  // ============================================================

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;

    if (notification == null) {
      return;
    }

    final orderId =
        (message.data['orderId'] ?? '').toString();

    final payload = jsonEncode({
      'orderId': orderId,
      'type': message.data['type'] ?? '',
    });

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  // ============================================================
  // REMOTE NOTIFICATION TAP
  // ============================================================

  static void _onRemoteNotificationTap(
    RemoteMessage message,
  ) {
    final type =
        (message.data['type'] ?? '').toString();

    final orderId =
        (message.data['orderId'] ?? '').toString().trim();

    if (orderId.isEmpty) {
      debugPrint(
        'Notification tapped without orderId. Type: $type',
      );
      return;
    }

    _pendingOrderId = orderId;

    unawaited(_openOrderWhenReady());
  }

  // ============================================================
  // LOCAL NOTIFICATION TAP
  // ============================================================

  static void _onLocalNotificationTap(
    NotificationResponse response,
  ) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final data =
          jsonDecode(payload) as Map<String, dynamic>;

      final orderId =
          (data['orderId'] ?? '').toString().trim();

      if (orderId.isEmpty) {
        return;
      }

      _pendingOrderId = orderId;

      unawaited(_openOrderWhenReady());
    } catch (e) {
      debugPrint(
        'Local notification payload error: $e',
      );
    }
  }

  // ============================================================
  // OPEN ORDER WHEN APP IS READY
  // ============================================================

  static Future<void> _openOrderWhenReady() async {
    if (_navigationInProgress) {
      return;
    }

    _navigationInProgress = true;

    try {
      // Splash aur authentication flow ko complete hone ka
      // samay do.
      for (var attempt = 0; attempt < 30; attempt++) {
        final navigator =
            JambooApp.navigatorKey.currentState;

        final user = FirebaseAuth.instance.currentUser;

        if (navigator != null && user != null) {
          break;
        }

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );
      }

      final orderId = _pendingOrderId;

      if (orderId == null || orderId.isEmpty) {
        return;
      }

      final navigator =
          JambooApp.navigatorKey.currentState;

      final user = FirebaseAuth.instance.currentUser;

      if (navigator == null || user == null) {
        debugPrint(
          'Cannot open notification order: '
          'navigator or authenticated user unavailable.',
        );
        return;
      }

      // Firestore se order fetch karo.
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        debugPrint('Notification order not found: $orderId');
        _pendingOrderId = null;
        return;
      }

      final data = orderDoc.data();

      if (data == null) {
        _pendingOrderId = null;
        return;
      }

      // Sirf isi logged-in customer ka order open hoga.
      final orderUserId =
          (data['userId'] ?? '').toString();

      if (orderUserId != user.uid) {
        debugPrint(
          'Notification order does not belong '
          'to the current customer.',
        );
        _pendingOrderId = null;
        return;
      }

      // OrderModel ke required orderId ko ensure karo.
      data['orderId'] = orderDoc.id;

      // Authentication/order fetch ke dauran notification
      // change ho gayi ho toh purana order mat kholo.
      if (_pendingOrderId != orderId) {
        return;
      }

      final order = OrderModel.fromMap(data);

      // Existing OrderDetailsScreen hi use hoga.
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailsScreen(
            order: order,
          ),
        ),
      );

      _pendingOrderId = null;
    } catch (e, stackTrace) {
      debugPrint(
        'Order notification navigation error: $e',
      );
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _navigationInProgress = false;

      // Agar doosri notification aayi ho toh use bhi handle karo.
      if (_pendingOrderId != null) {
        unawaited(_openOrderWhenReady());
      }
    }
  }
}
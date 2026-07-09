import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  FCMService._();

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel
      _channel = AndroidNotificationChannel(
    'jamboo_notifications',
    'Jamboo Notifications',
    description:
        'Order updates and important notifications',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (kIsWeb) {
  return;
}
    final FirebaseMessaging messaging =
        FirebaseMessaging.instance;

    // Ask notification permission
    NotificationSettings settings =
        await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print(
      "Notification Permission: ${settings.authorizationStatus}",
    );

    // Device Token
    final token = await messaging.getToken();

    print("FCM TOKEN:");
    print(token);

    // Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          _channel,
        );

    // Initialization
    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings
        initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {

        final notification =
            message.notification;

        if (notification == null) return;

        _localNotifications.show(
          notification.hashCode,

          notification.title,

          notification.body,

          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription:
                  _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      },
    );

    // Token Refresh
    FirebaseMessaging.instance
        .onTokenRefresh
        .listen((newToken) {
      print("New FCM Token:");
      print(newToken);
    });
  }
}
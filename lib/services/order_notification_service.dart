import 'package:uuid/uuid.dart';

import '../models/notification_model.dart';
import 'notification_service.dart';

class OrderNotificationService {
  OrderNotificationService._();

  static final NotificationService
      _notificationService =
      NotificationService();

  static const Uuid _uuid = Uuid();

  // ==========================
  // Order Placed
  // ==========================

  static Future<void> orderPlaced({
    required String userId,
    required String orderId,
  }) async {
    await _send(
      userId: userId,
      orderId: orderId,
      type: "OrderPlaced",
      title: "Order Placed 🎉",
      message:
          "Your order has been placed successfully and is being sent to the restaurant.",
    );
  }

  // ==========================
  // Order Accepted
  // ==========================

  static Future<void> orderAccepted({
    required String userId,
    required String orderId,
  }) async {
    await _send(
      userId: userId,
      orderId: orderId,
      type: "Accepted",
      title: "Restaurant Accepted 👨‍🍳",
      message:
          "The restaurant has accepted your order and will start preparing it soon.",
    );
  }

  // ==========================
  // Preparing
  // ==========================

  static Future<void> preparing({
    required String userId,
    required String orderId,
  }) async {
    await _send(
      userId: userId,
      orderId: orderId,
      type: "Preparing",
      title: "Preparing Your Food 🍳",
      message:
          "Our chefs are preparing your delicious meal.",
    );
  }

  // ==========================
  // Ready
  // ==========================

  static Future<void> ready({
    required String userId,
    required String orderId,
  }) async {
    await _send(
      userId: userId,
      orderId: orderId,
      type: "Ready",
      title: "Order Ready 📦",
      message:
          "Your order has been packed and is ready for pickup.",
    );
  }

  // ==========================
  // Out For Delivery
  // ==========================

  static Future<void> outForDelivery({
    required String userId,
    required String orderId,
  }) async {
    await _send(
      userId: userId,
      orderId: orderId,
      type: "OutForDelivery",
      title: "Out for Delivery 🛵",
      message:
          "Your order is on the way. Get ready to enjoy your meal!",
    );
  }

  // ==========================
  // Delivered
  // ==========================

  static Future<void> delivered({
    required String userId,
    required String orderId,
  }) async {
    await _send(
      userId: userId,
      orderId: orderId,
      type: "Delivered",
      title: "Order Delivered ✅",
      message:
          "Enjoy your meal! We hope you have a wonderful dining experience.",
    );
  }

  // ==========================
  // Cancelled
  // ==========================

  static Future<void> cancelled({
    required String userId,
    required String orderId,
  }) async {
    await _send(
      userId: userId,
      orderId: orderId,
      type: "Cancelled",
      title: "Order Cancelled ❌",
      message:
          "Your order has been cancelled successfully.",
    );
  }

  // ==========================
  // Internal Method
  // ==========================

 static Future<void> _send({
  required String userId,
  required String orderId,
  required String type,
  required String title,
  required String message,
}) async {
  final notification = NotificationModel(
    notificationId: _uuid.v4(),
    userId: userId,
    title: title,
    message: message,
    type: type,
    isRead: false,
    createdAt: DateTime.now(),
    orderId: orderId,
  );

  await _notificationService.createNotification(
    notification: notification,
  );
}
}
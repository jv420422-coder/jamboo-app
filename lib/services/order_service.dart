import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/order_model.dart';
import 'order_notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<void> placeOrder(
    OrderModel order, {
    String? couponCode,
  }) async {
    final callable =
        _functions.httpsCallable(
      'customerPlaceOrder',
    );

    await callable.call({
      'orderId': order.orderId,
      'orderNumber': order.orderNumber,
      'restaurantId': order.restaurantId,
      'restaurantName': order.restaurantName,
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'items': order.items,
      'deliveryAddress': order.deliveryAddress,
      'customerLatitude':
          order.customerLatitude,
      'customerLongitude':
          order.customerLongitude,
      'paymentMethod': order.paymentMethod,
      'subtotal': order.subtotal,
      'couponCode':
          couponCode?.trim().isNotEmpty == true
              ? couponCode!.trim().toUpperCase()
              : null,
      'customerNote': order.customerNote,
    });

    await OrderNotificationService.orderPlaced(
      userId: order.userId,
      orderId: order.orderId,
    );

    await OrderNotificationService.restaurantNewOrder(
      restaurantId: order.restaurantId,
      orderId: order.orderId,
      orderNumber: order.orderNumber,
    );
  }

  Stream<QuerySnapshot> getUserOrders(
    String userId,
  ) {
    return _firestore
        .collection("orders")
        .where(
          "userId",
          isEqualTo: userId,
        )
        .orderBy(
          "createdAt",
          descending: true,
        )
        .snapshots();
  }

  Future<DocumentSnapshot> getOrder(
    String orderId,
  ) {
    return _firestore
        .collection("orders")
        .doc(orderId)
        .get();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final doc = await _firestore
        .collection("orders")
        .doc(orderId)
        .get();

    if (!doc.exists) {
      throw Exception("Order not found");
    }

    final data = doc.data()!;

    await _firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "orderStatus": status,
      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    final String userId = data["userId"];

    switch (status) {
      case "Accepted":
        await OrderNotificationService.orderAccepted(
          userId: userId,
          orderId: orderId,
        );
        break;

      case "Preparing":
        await OrderNotificationService.preparing(
          userId: userId,
          orderId: orderId,
        );
        break;

      case "Ready":
        await OrderNotificationService.ready(
          userId: userId,
          orderId: orderId,
        );
        break;

      case "OutForDelivery":
        await OrderNotificationService.outForDelivery(
          userId: userId,
          orderId: orderId,
        );
        break;

      case "Delivered":
        await OrderNotificationService.delivered(
          userId: userId,
          orderId: orderId,
        );
        break;

      default:
        break;
    }
  }

  Future<void> cancelOrder({
    required String orderId,
    required String cancelledBy,
  }) async {
    final doc = await _firestore
        .collection("orders")
        .doc(orderId)
        .get();

    if (!doc.exists) {
      throw Exception("Order not found");
    }

    final data = doc.data()!;

    final String userId = data["userId"];

    final createdAt =
        (data["createdAt"] as Timestamp)
            .toDate();

    final difference =
        DateTime.now().difference(
      createdAt,
    );

    if (difference.inMinutes >= 2) {
      throw Exception(
        "Cancellation time has expired.",
      );
    }

    await _firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "orderStatus": "Cancelled",
      "cancelledBy": cancelledBy,
      "cancelledAt":
          FieldValue.serverTimestamp(),
      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    await OrderNotificationService.cancelled(
      userId: userId,
      orderId: orderId,
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchOrder(
    String orderId,
  ) {
    return _firestore
        .collection("orders")
        .doc(orderId)
        .snapshots();
  }

  Future<void> updatePaymentStatus({
    required String orderId,
    required String status,
  }) async {
    await _firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "paymentStatus": status,
    });
  }

  Future<void> updateCustomerNote({
    required String orderId,
    required String note,
  }) async {
    await _firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "customerNote": note,
      "updatedAt":
          FieldValue.serverTimestamp(),
    });
  }
}
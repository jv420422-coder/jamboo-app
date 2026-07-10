import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import 'order_notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> placeOrder(OrderModel order) async {
  await _firestore
      .collection("orders")
      .doc(order.orderId)
      .set({
    ...order.toMap(),

    // Firestore server time
    "createdAt": FieldValue.serverTimestamp(),
  });

  await OrderNotificationService.orderPlaced(
    userId: order.userId,
    orderId: order.orderId,
  );
}

    Stream<QuerySnapshot> getUserOrders(String userId) {
  return _firestore
      .collection("orders")
      .where("userId", isEqualTo: userId)
      .orderBy(
        "createdAt",
        descending: true,
      )
      .snapshots();
}

  Future<DocumentSnapshot> getOrder(
      String orderId) {
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
    "updatedAt": FieldValue.serverTimestamp(),
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
      (data["createdAt"] as Timestamp).toDate();

  final difference =
      DateTime.now().difference(createdAt);

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
Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrder(
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
    "updatedAt": FieldValue.serverTimestamp(),
  });
}
}
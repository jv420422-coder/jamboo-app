import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

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
  await _firestore
      .collection("orders")
      .doc(orderId)
      .update({
    "orderStatus": status,
    "updatedAt": FieldValue.serverTimestamp(),
  });
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
}
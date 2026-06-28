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

    Stream<QuerySnapshot> getUserOrders(
    String userId) {

  return _firestore
      .collection("orders")
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
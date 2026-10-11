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

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> placeOrder(
    OrderModel order, {
    String? couponCode,
    String? paymentIntentId,
  }) async {
    final callable =
        _functions.httpsCallable(
      'customerPlaceOrder',
    );

    await callable.call({
      'orderId':
          order.orderId,

      'orderNumber':
          order.orderNumber,

      'restaurantId':
          order.restaurantId,

      'restaurantName':
          order.restaurantName,

      'customerName':
          order.customerName,

      'customerPhone':
          order.customerPhone,

      'items':
          order.items,

      'deliveryAddress':
          order.deliveryAddress,

      'customerLatitude':
          order.customerLatitude,

      'customerLongitude':
          order.customerLongitude,

      'paymentMethod':
          order.paymentMethod,

      'subtotal':
          order.subtotal,

      'couponCode':
          couponCode?.trim().isNotEmpty == true
              ? couponCode!
                  .trim()
                  .toUpperCase()
              : null,

      'customerNote':
          order.customerNote,

      'paymentIntentId':
          paymentIntentId,
    });

    await OrderNotificationService.orderPlaced(
      userId:
          order.userId,
      orderId:
          order.orderId,
    );

    await OrderNotificationService.restaurantNewOrder(
      restaurantId:
          order.restaurantId,
      orderId:
          order.orderId,
      orderNumber:
          order.orderNumber,
    );
  }

  // ============================================================
  // RAZORPAY - CREATE PAYMENT INTENT
  // ============================================================

  Future<Map<String, dynamic>> createPaymentIntent({
    required String orderId,
    required String orderNumber,
    required String restaurantId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required double customerLatitude,
    required double customerLongitude,
    required String customerName,
    required String customerPhone,
    String? couponCode,
    String? customerNote,
  }) async {
    final callable =
        _functions.httpsCallable(
      'razorpayCreatePaymentIntent',
    );

    final result =
        await callable.call({
      'orderId':
          orderId,

      'orderNumber':
          orderNumber,

      'restaurantId':
          restaurantId,

      'paymentMethod':
          paymentMethod,

      'items':
          items,

      'deliveryAddress':
          deliveryAddress,

      'customerLatitude':
          customerLatitude,

      'customerLongitude':
          customerLongitude,

      'customerName':
          customerName,

      'customerPhone':
          customerPhone,

      'couponCode':
          couponCode?.trim().isNotEmpty == true
              ? couponCode!
                  .trim()
                  .toUpperCase()
              : null,

      'customerNote':
          customerNote,
    });

    return Map<String, dynamic>.from(
      result.data as Map,
    );
  }

  // ============================================================
  // RAZORPAY - CREATE RAZORPAY ORDER
  // ============================================================

  Future<Map<String, dynamic>> createRazorpayOrder({
    required String paymentId,
  }) async {
    final callable =
        _functions.httpsCallable(
      'razorpayCreateOrder',
    );

    final result =
        await callable.call({
      'paymentId':
          paymentId,
    });

    return Map<String, dynamic>.from(
      result.data as Map,
    );
  }

  // ============================================================
  // RAZORPAY - VERIFY PAYMENT
  // ============================================================

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String paymentId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final callable =
        _functions.httpsCallable(
      'razorpayVerifyPayment',
    );

    final result =
        await callable.call({
      'paymentId':
          paymentId,

      'razorpayPaymentId':
          razorpayPaymentId,

      'razorpayOrderId':
          razorpayOrderId,

      'razorpaySignature':
          razorpaySignature,
    });

    return Map<String, dynamic>.from(
      result.data as Map,
    );
  }

  // ============================================================
  // GET USER ORDERS
  // ============================================================

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

  // ============================================================
  // GET SINGLE ORDER
  // ============================================================

  Future<DocumentSnapshot> getOrder(
    String orderId,
  ) {
    return _firestore
        .collection("orders")
        .doc(orderId)
        .get();
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final doc =
        await _firestore
            .collection("orders")
            .doc(orderId)
            .get();

    if (!doc.exists) {
      throw Exception(
        "Order not found",
      );
    }

    final data =
        doc.data()!;

    await _firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "orderStatus":
          status,

      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    final String userId =
        data["userId"];

    switch (status) {
      case "Accepted":
        await OrderNotificationService.orderAccepted(
          userId:
              userId,
          orderId:
              orderId,
        );
        break;

      case "Preparing":
        await OrderNotificationService.preparing(
          userId:
              userId,
          orderId:
              orderId,
        );
        break;

      case "Ready":
        await OrderNotificationService.ready(
          userId:
              userId,
          orderId:
              orderId,
        );
        break;

      case "OutForDelivery":
        await OrderNotificationService.outForDelivery(
          userId:
              userId,
          orderId:
              orderId,
        );
        break;

      case "Delivered":
        await OrderNotificationService.delivered(
          userId:
              userId,
          orderId:
              orderId,
        );
        break;

      default:
        break;
    }
  }

  // ============================================================
  // CANCEL ORDER
  // ============================================================

  Future<void> cancelOrder({
    required String orderId,
    required String cancelledBy,
  }) async {
    final doc =
        await _firestore
            .collection("orders")
            .doc(orderId)
            .get();

    if (!doc.exists) {
      throw Exception(
        "Order not found",
      );
    }

    final data =
        doc.data()!;

    final String userId =
        data["userId"];

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
      "orderStatus":
          "Cancelled",

      "cancelledBy":
          cancelledBy,

      "cancelledAt":
          FieldValue.serverTimestamp(),

      "updatedAt":
          FieldValue.serverTimestamp(),
    });

    await OrderNotificationService.cancelled(
      userId:
          userId,
      orderId:
          orderId,
    );
  }

  // ============================================================
  // WATCH ORDER
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchOrder(
    String orderId,
  ) {
    return _firestore
        .collection("orders")
        .doc(orderId)
        .snapshots();
  }

  // ============================================================
  // UPDATE PAYMENT STATUS
  // ============================================================
  //
  // IMPORTANT:
  // This method is NOT used for Razorpay online payment
  // verification. Razorpay payments are verified by the
  // backend using verifyRazorpayPayment().
  //
  // Keeping this method because other existing parts of
  // the app may still use it.
  // ============================================================

  Future<void> updatePaymentStatus({
    required String orderId,
    required String status,
  }) async {
    await _firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "paymentStatus":
          status,
    });
  }

  // ============================================================
  // UPDATE CUSTOMER NOTE
  // ============================================================

  Future<void> updateCustomerNote({
    required String orderId,
    required String note,
  }) async {
    await _firestore
        .collection("orders")
        .doc(orderId)
        .update({
      "customerNote":
          note,

      "updatedAt":
          FieldValue.serverTimestamp(),
    });
  }
}
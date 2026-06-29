import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String orderNumber;
  final String userId;

  final String restaurantId;
  final String restaurantName;

  final List<Map<String, dynamic>> items;

  final Map<String, dynamic> deliveryAddress;

  final String paymentMethod;
  final String paymentStatus;

  final String orderStatus;

  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;

final DateTime createdAt;

final DateTime? updatedAt;
final DateTime? cancelledAt;
final String? cancelledBy;

  OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
required this.createdAt,

this.updatedAt,
this.cancelledAt,
this.cancelledBy,
});

  Map<String, dynamic> toMap() {
    return {
      "orderId": orderId,
      "orderNumber": orderNumber,
      "userId": userId,
      "restaurantId": restaurantId,
      "restaurantName": restaurantName,
      "items": items,
      "deliveryAddress": deliveryAddress,
      "paymentMethod": paymentMethod,
      "paymentStatus": paymentStatus,
      "orderStatus": orderStatus,
      "subtotal": subtotal,
      "deliveryFee": deliveryFee,
      "discount": discount,
"totalAmount": totalAmount,
"createdAt": createdAt,

"updatedAt": updatedAt,
"cancelledAt": cancelledAt,
"cancelledBy": cancelledBy,

};
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map["orderId"] ?? "",
      orderNumber: map["orderNumber"] ?? "",
      userId: map["userId"] ?? "",
      restaurantId: map["restaurantId"] ?? "",
      restaurantName: map["restaurantName"] ?? "",
      items: List<Map<String, dynamic>>.from(
        map["items"] ?? [],
      ),
      deliveryAddress:
          Map<String, dynamic>.from(
        map["deliveryAddress"] ?? {},
      ),
      paymentMethod:
          map["paymentMethod"] ?? "",
      paymentStatus:
          map["paymentStatus"] ?? "",
      orderStatus:
          map["orderStatus"] ?? "",
      subtotal:
          (map["subtotal"] ?? 0).toDouble(),
      deliveryFee:
          (map["deliveryFee"] ?? 0).toDouble(),
      discount:
    (map["discount"] ?? 0).toDouble(),

totalAmount:
    (map["totalAmount"] ?? 0).toDouble(),

createdAt:
    (map["createdAt"] as Timestamp).toDate(),

updatedAt: map["updatedAt"] != null
    ? (map["updatedAt"] as Timestamp).toDate()
    : null,

cancelledAt: map["cancelledAt"] != null
    ? (map["cancelledAt"] as Timestamp).toDate()
    : null,

cancelledBy: map["cancelledBy"],

    );
  }
}
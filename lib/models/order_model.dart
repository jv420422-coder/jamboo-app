import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String orderNumber;

  final String userId;
  final String customerName;
  final String customerPhone;

  // Delivery Partner
  final String deliveryPartnerId;
  final String deliveryPartnerName;
  final String deliveryPartnerPhone;
  final String vehicleNumber;

  // Restaurant
  final String restaurantId;
  final String restaurantName;
  final String restaurantAddress;

  final double restaurantLatitude;
  final double restaurantLongitude;

  // Customer
  final double customerLatitude;
  final double customerLongitude;

  final List<Map<String, dynamic>> items;

  final Map<String, dynamic> deliveryAddress;

  final String paymentMethod;
  final String paymentStatus;

  final String orderStatus;

  final double subtotal;
  final double deliveryFee;
  final double longDistanceCharge;
  final double platformFee;
  final double discount;
  final double totalAmount;

  final String? couponCode;
  final String? couponFundedBy;

  final DateTime createdAt;

  final DateTime? updatedAt;
  final DateTime? cancelledAt;

  final String? cancelledBy;

  final bool isRated;
  final double rating;

  final String? customerNote;

  OrderModel({
    required this.orderId,
    required this.orderNumber,

    required this.userId,
    required this.customerName,
    required this.customerPhone,

    required this.deliveryPartnerId,
    required this.deliveryPartnerName,
    required this.deliveryPartnerPhone,
    required this.vehicleNumber,

    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantAddress,

    required this.restaurantLatitude,
    required this.restaurantLongitude,

    required this.items,
    required this.deliveryAddress,

    required this.customerLatitude,
    required this.customerLongitude,

    required this.paymentMethod,
    required this.paymentStatus,

    required this.orderStatus,

    required this.subtotal,
    required this.deliveryFee,
    required this.longDistanceCharge,
    required this.platformFee,
    required this.discount,
    required this.totalAmount,

    this.couponCode,
    this.couponFundedBy,

    required this.createdAt,

    this.updatedAt,
    this.cancelledAt,
    this.cancelledBy,

    this.isRated = false,
    this.rating = 0,

    this.customerNote,
  });

  Map<String, dynamic> toMap() {
    return {
      "orderId": orderId,
      "orderNumber": orderNumber,

      "userId": userId,
      "customerName": customerName,
      "customerPhone": customerPhone,

      "deliveryPartnerId": deliveryPartnerId,
      "deliveryPartnerName": deliveryPartnerName,
      "deliveryPartnerPhone": deliveryPartnerPhone,
      "vehicleNumber": vehicleNumber,

      "restaurantId": restaurantId,
      "restaurantName": restaurantName,
      "restaurantAddress": restaurantAddress,

      "restaurantLatitude": restaurantLatitude,
      "restaurantLongitude": restaurantLongitude,

      "items": items,
      "deliveryAddress": deliveryAddress,

      "customerLatitude": customerLatitude,
      "customerLongitude": customerLongitude,

      "paymentMethod": paymentMethod,
      "paymentStatus": paymentStatus,

      "orderStatus": orderStatus,

      "subtotal": subtotal,
      "deliveryFee": deliveryFee,
      "longDistanceCharge": longDistanceCharge,
      "platformFee": platformFee,
      "discount": discount,
      "totalAmount": totalAmount,

      "couponCode": couponCode,
      "couponFundedBy": couponFundedBy,

      "createdAt": createdAt,

      "updatedAt": updatedAt,
      "cancelledAt": cancelledAt,
      "cancelledBy": cancelledBy,

      "isRated": isRated,
      "rating": rating,

      "customerNote": customerNote,
    };
  }

  factory OrderModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return OrderModel(
      orderId: map["orderId"] ?? "",
      orderNumber: map["orderNumber"] ?? "",

      userId: map["userId"] ?? "",
      customerName: map["customerName"] ?? "",
      customerPhone: map["customerPhone"] ?? "",

      deliveryPartnerId:
          map["deliveryPartnerId"] ?? "",
      deliveryPartnerName:
          map["deliveryPartnerName"] ?? "",

      deliveryPartnerPhone:
          map["deliveryPartnerPhone"] ?? "",

      vehicleNumber:
          map["vehicleNumber"] ?? "",

      restaurantId:
          map["restaurantId"] ?? "",

      restaurantName:
          map["restaurantName"] ?? "",

      restaurantAddress:
          map["restaurantAddress"] ?? "",

      restaurantLatitude:
          (map["restaurantLatitude"] ?? 0)
              .toDouble(),

      restaurantLongitude:
          (map["restaurantLongitude"] ?? 0)
              .toDouble(),

      items:
          List<Map<String, dynamic>>.from(
        map["items"] ?? [],
      ),

      deliveryAddress:
          Map<String, dynamic>.from(
        map["deliveryAddress"] ?? {},
      ),

      customerLatitude:
          (map["customerLatitude"] ?? 0)
              .toDouble(),

      customerLongitude:
          (map["customerLongitude"] ?? 0)
              .toDouble(),

      paymentMethod:
          map["paymentMethod"] ?? "",

      paymentStatus:
          map["paymentStatus"] ?? "",

      orderStatus:
          map["orderStatus"] ?? "",

      subtotal:
          (map["subtotal"] ?? 0)
              .toDouble(),

      deliveryFee:
          (map["deliveryFee"] ?? 0)
              .toDouble(),

      longDistanceCharge:
          (map["longDistanceCharge"] ?? 0)
              .toDouble(),

      platformFee:
          (map["platformFee"] ?? 0)
              .toDouble(),

      discount:
          (map["discount"] ?? 0)
              .toDouble(),

      totalAmount:
          (map["totalAmount"] ?? 0)
              .toDouble(),

      couponCode:
          map["couponCode"],

      couponFundedBy:
          map["couponFundedBy"],

      createdAt:
          (map["createdAt"] as Timestamp)
              .toDate(),

      updatedAt:
          map["updatedAt"] != null
              ? (map["updatedAt"]
                      as Timestamp)
                  .toDate()
              : null,

      cancelledAt:
          map["cancelledAt"] != null
              ? (map["cancelledAt"]
                      as Timestamp)
                  .toDate()
              : null,

      cancelledBy:
          map["cancelledBy"],

      isRated:
          map["isRated"] ?? false,

      rating:
          (map["rating"] ?? 0)
              .toDouble(),

      customerNote:
          map["customerNote"],
    );
  }
}
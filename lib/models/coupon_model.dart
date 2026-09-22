import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final String description;

  final String discountType;
  final double discountValue;
  final double maximumDiscount;
  final double minimumOrderValue;

  final DateTime? startDate;
  final DateTime? endDate;

  final bool isActive;
  final String fundedBy;

  final List<String> applicableRestaurants;
  final List<String> providedToRestaurants;

  final int totalUsageLimit;
  final int usedCount;
  final int perCustomerLimit;
  final int customerUsedCount;

  final String restaurantStatus;

  const CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.maximumDiscount,
    required this.minimumOrderValue,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.fundedBy,
    required this.applicableRestaurants,
    required this.providedToRestaurants,
    required this.totalUsageLimit,
    required this.usedCount,
    required this.perCustomerLimit,
    required this.customerUsedCount,
    required this.restaurantStatus,
  });

  factory CouponModel.fromMap(
    Map<String, dynamic> map, {
    String? restaurantId,
    int customerUsedCount = 0,
  }) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value);
      }

      return null;
    }

    final applicableRestaurants =
        map["applicableRestaurants"] is List
            ? List<String>.from(
                map["applicableRestaurants"],
              )
            : <String>[];

    final providedToRestaurants =
        map["providedToRestaurants"] is List
            ? List<String>.from(
                map["providedToRestaurants"],
              )
            : <String>[];

    final statusMap =
        map["restaurantCouponStatus"] is Map
            ? Map<String, dynamic>.from(
                map["restaurantCouponStatus"],
              )
            : <String, dynamic>{};

    final restaurantStatus =
        restaurantId != null
            ? statusMap[restaurantId] ?? "pending"
            : "pending";

    return CouponModel(
      id: idOrCode(map),
      code: map["couponCode"] ?? "",
      description: map["description"] ?? "",
      discountType:
          map["discountType"] ?? "percentage",
      discountValue:
          numberValue(map["discountValue"]),
      maximumDiscount:
          numberValue(map["maximumDiscount"]),
      minimumOrderValue:
          numberValue(map["minimumOrderValue"]),
      startDate: parseDate(map["startDate"]),
      endDate: parseDate(map["endDate"]),
      isActive: map["isActive"] ?? true,
      fundedBy:
          map["fundedBy"] ?? "jamboo",
      applicableRestaurants:
          applicableRestaurants,
      providedToRestaurants:
          providedToRestaurants,
      totalUsageLimit:
          integerValue(map["totalUsageLimit"]),
      usedCount:
          integerValue(map["usedCount"]),
      perCustomerLimit:
          integerValue(map["perCustomerLimit"]),
      customerUsedCount:
          customerUsedCount,
      restaurantStatus:
          restaurantStatus,
    );
  }

  static String idOrCode(
    Map<String, dynamic> map,
  ) {
    final code = map["couponCode"];

    if (code is String && code.isNotEmpty) {
      return code;
    }

    return "";
  }

  static double numberValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }

  static int integerValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsed = int.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }
}
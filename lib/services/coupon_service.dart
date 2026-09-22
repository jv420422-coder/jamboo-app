import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/coupon_model.dart';

class CouponService {
  CouponService._();

  static final CouponService instance =
      CouponService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<List<CouponModel>> getRestaurantCoupons({
    required String restaurantId,
  }) async {
    return [];
  }

  Future<bool> validateCoupon({
  required CouponModel coupon,
  required double cartAmount,
  required String userId,
  required String restaurantId,
}) async {
  try {
    final result = await _validate(
      couponCode: coupon.code,
      restaurantId: restaurantId,
      cartAmount: cartAmount,
    );

    return result.success;
  } catch (_) {
    return false;
  }
}

  double calculateDiscount({
    required CouponModel coupon,
    required double cartAmount,
  }) {
    if (cartAmount <= 0) {
      return 0;
    }

    if (coupon.discountType == "fixed") {
      return coupon.discountValue > cartAmount
          ? cartAmount
          : coupon.discountValue;
    }

    if (coupon.discountType == "percentage") {
      double discount =
          cartAmount *
          coupon.discountValue /
          100;

      if (coupon.maximumDiscount > 0) {
        discount =
            discount > coupon.maximumDiscount
                ? coupon.maximumDiscount
                : discount;
      }

      if (discount > cartAmount) {
        discount = cartAmount;
      }

      return double.parse(
        discount.toStringAsFixed(2),
      );
    }

    return 0;
  }

  Future<CouponModel?> applyCoupon({
    required String couponCode,
    required String restaurantId,
    required double cartAmount,
    required String userId,
  }) async {
    final result = await _validate(
      couponCode: couponCode,
      restaurantId: restaurantId,
      cartAmount: cartAmount,
    );

    if (!result.success) {
      return null;
    }

    final data = result.data;

    return CouponModel.fromMap(
      data,
      restaurantId: restaurantId,
      customerUsedCount:
          _toInt(data["customerUsedCount"]),
    );
  }

  Future<void> removeCoupon() async {}

  Future<_CouponValidationResult> _validate({
    required String couponCode,
    required String restaurantId,
    required double cartAmount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        "Please login to apply a coupon.",
      );
    }

    final callable =
        _functions.httpsCallable(
      "validateCoupon",
    );

    final response = await callable.call({
      "couponCode": couponCode.trim().toUpperCase(),
      "restaurantId": restaurantId,
      "subtotal": cartAmount,
    });

    final data =
        Map<String, dynamic>.from(
      response.data as Map,
    );

    return _CouponValidationResult(
      success: data["success"] == true,
      data: data,
    );
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}

class _CouponValidationResult {
  final bool success;
  final Map<String, dynamic> data;

  const _CouponValidationResult({
    required this.success,
    required this.data,
  });
}
import '../models/coupon_model.dart';

class CouponService {
  CouponService._();

  /// Restaurant ke active coupons layega
  Future<List<CouponModel>> getRestaurantCoupons({
    required String restaurantId,
  }) async {
    return [];
  }

  /// Coupon valid hai ya nahi
  Future<bool> validateCoupon({
    required CouponModel coupon,
    required double cartAmount,
    required String userId,
  }) async {
    return false;
  }

  /// Discount calculate karega
  double calculateDiscount({
    required CouponModel coupon,
    required double cartAmount,
  }) {
    return 0;
  }

  /// Coupon apply karega
  Future<CouponModel?> applyCoupon({
    required String couponCode,
    required String restaurantId,
    required double cartAmount,
    required String userId,
  }) async {
    return null;
  }

  /// Coupon remove karega
  Future<void> removeCoupon() async {}
}
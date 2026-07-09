class CheckoutService {
  CheckoutService._();

  static final CheckoutService instance =
      CheckoutService._();

  String? selectedAddressId;
  String? appliedCouponCode;
  bool couponApplied = false;

  void clear() {
    selectedAddressId = null;
    appliedCouponCode = null;
    couponApplied = false;
  }
}
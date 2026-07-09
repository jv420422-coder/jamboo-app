import 'cart_item_model.dart';
import 'coupon_model.dart';
import 'bill_summary_model.dart';

class CheckoutSessionModel {
  final String restaurantId;
  final String restaurantName;

  final List<CartItemModel> cartItems;

  final String? selectedAddressId;

  final CouponModel? coupon;

  final BillSummaryModel billSummary;

  final String paymentMethod;

  const CheckoutSessionModel({
    required this.restaurantId,
    required this.restaurantName,
    required this.cartItems,
    required this.selectedAddressId,
    required this.coupon,
    required this.billSummary,
    required this.paymentMethod,
  });
}
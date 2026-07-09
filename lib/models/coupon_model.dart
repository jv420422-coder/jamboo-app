class CouponModel {
  final String id;
  final String restaurantId;
  final String code;
  final String title;
  final String description;

  final String discountType;
  final double discountValue;

  final double minimumOrder;
  final double? maximumDiscount;

  final bool freeDelivery;
  final bool isActive;

  final DateTime validFrom;
  final DateTime validTill;

  final int usageLimit;
  final int perUserLimit;

  const CouponModel({
    required this.id,
    required this.restaurantId,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minimumOrder,
    this.maximumDiscount,
    required this.freeDelivery,
    required this.isActive,
    required this.validFrom,
    required this.validTill,
    required this.usageLimit,
    required this.perUserLimit,
  });
}
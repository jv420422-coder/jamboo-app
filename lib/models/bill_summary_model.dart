class BillSummaryModel {
  final double itemsTotal;
  final double deliveryFee;
  final double platformFee;
  final double couponDiscount;
  final double grandTotal;
  final String? couponCode;

  const BillSummaryModel({
    required this.itemsTotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.couponDiscount,
    required this.grandTotal,
    this.couponCode,
  });

  Map<String, dynamic> toMap() {
    return {
      "itemsTotal": itemsTotal,
      "deliveryFee": deliveryFee,
      "platformFee": platformFee,
      "couponDiscount": couponDiscount,
      "grandTotal": grandTotal,
      "couponCode": couponCode,
    };
  }

  factory BillSummaryModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return BillSummaryModel(
      itemsTotal: (map["itemsTotal"] ?? 0).toDouble(),
      deliveryFee: (map["deliveryFee"] ?? 0).toDouble(),
      platformFee: (map["platformFee"] ?? 0).toDouble(),
      couponDiscount: (map["couponDiscount"] ?? 0).toDouble(),
      grandTotal: (map["grandTotal"] ?? 0).toDouble(),
      couponCode: map["couponCode"],
    );
  }
}
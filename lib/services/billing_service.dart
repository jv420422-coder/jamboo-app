import '../models/bill_summary_model.dart';

class BillingService {
  BillingService._();

  static BillSummaryModel calculateBill({
    required double itemsTotal,
    bool couponApplied = false,
    String? couponCode,
  }) {
    const double deliveryFee = 30;
    const double platformFee = 10;

    final double couponDiscount =
        couponApplied ? 50 : 0;

    final double grandTotal =
        itemsTotal +
        deliveryFee +
        platformFee -
        couponDiscount;

    return BillSummaryModel(
      itemsTotal: itemsTotal,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      couponDiscount: couponDiscount,
      grandTotal: grandTotal,
      couponCode: couponApplied
          ? couponCode
          : null,
    );
  }
}
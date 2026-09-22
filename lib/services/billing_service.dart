import '../models/bill_summary_model.dart';
import 'business_rules_service.dart';

class BillingService {
  BillingService._();

  static double _deliveryFee = 30;
  static double _platformFee = 10;
  static double _freeDeliveryAbove = 0;

  static bool _rulesLoaded = false;

  static Future<void> loadBusinessRules() async {
    try {
      final rules =
          await BusinessRulesService.instance
              .getBusinessRules();

      _deliveryFee =
          (rules['deliveryFee'] as num?)?.toDouble() ??
              30;

      _platformFee =
          (rules['platformFee'] as num?)?.toDouble() ??
              10;

      _freeDeliveryAbove =
          (rules['freeDeliveryAbove'] as num?)?.toDouble() ??
              0;

      _rulesLoaded = true;
    } catch (_) {
      _deliveryFee = 30;
      _platformFee = 10;
      _freeDeliveryAbove = 0;
      _rulesLoaded = false;
    }
  }

  static bool get rulesLoaded => _rulesLoaded;

  static BillSummaryModel calculateBill({
    required double itemsTotal,
    double couponDiscount = 0,
    String? couponCode,
  }) {
    double safeCouponDiscount =
        couponDiscount;

    if (safeCouponDiscount < 0) {
      safeCouponDiscount = 0;
    }

    if (safeCouponDiscount > itemsTotal) {
      safeCouponDiscount = itemsTotal;
    }

    double finalDeliveryFee =
        _deliveryFee;

    if (_freeDeliveryAbove > 0 &&
        itemsTotal >= _freeDeliveryAbove) {
      finalDeliveryFee = 0;
    }

    final double grandTotal =
        itemsTotal +
        finalDeliveryFee +
        _platformFee -
        safeCouponDiscount;

    return BillSummaryModel(
      itemsTotal: itemsTotal,
      deliveryFee: finalDeliveryFee,
      platformFee: _platformFee,
      couponDiscount: safeCouponDiscount,
      grandTotal: grandTotal,
      couponCode:
          safeCouponDiscount > 0
              ? couponCode
              : null,
    );
  }
}
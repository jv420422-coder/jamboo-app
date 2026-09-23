import 'package:geolocator/geolocator.dart';

import '../models/bill_summary_model.dart';
import 'business_rules_service.dart';

class BillingService {
  BillingService._();

  static double _deliveryFee = 30;
  static double _platformFee = 10;
  static double _freeDeliveryAbove = 0;
  static double _serviceableRadiusKm = 7;
  static double _longDistanceFreeRadiusKm = 3;
  static double _longDistanceCharge = 10;

  static bool _codEnabled = true;

  static bool _rulesLoaded = false;

  static Future<void> loadBusinessRules() async {
    try {
      final rules =
          await BusinessRulesService.instance
              .getBusinessRules();

      _deliveryFee =
          (rules['deliveryFee'] as num?)
                  ?.toDouble() ??
              30;

      _platformFee =
          (rules['platformFee'] as num?)
                  ?.toDouble() ??
              10;

      _freeDeliveryAbove =
          (rules['freeDeliveryAbove'] as num?)
                  ?.toDouble() ??
              0;

      _serviceableRadiusKm =
          (rules['serviceableRadiusKm'] as num?)
                  ?.toDouble() ??
              7;

      _longDistanceFreeRadiusKm =
          (rules['longDistanceFreeRadiusKm']
                      as num?)
                  ?.toDouble() ??
              3;

      _longDistanceCharge =
          (rules['longDistanceCharge'] as num?)
                  ?.toDouble() ??
              10;

      _codEnabled =
          rules['codEnabled'] as bool? ?? true;

      _rulesLoaded = true;
    } catch (_) {
      _deliveryFee = 30;
      _platformFee = 10;
      _freeDeliveryAbove = 0;
      _serviceableRadiusKm = 7;
      _longDistanceFreeRadiusKm = 3;
      _longDistanceCharge = 10;
      _codEnabled = true;
      _rulesLoaded = false;
    }
  }

  static bool get rulesLoaded =>
      _rulesLoaded;

  static bool get codEnabled =>
      _codEnabled;

  static double calculateDistanceKm({
    required double restaurantLatitude,
    required double restaurantLongitude,
    required double customerLatitude,
    required double customerLongitude,
  }) {
    final distanceMeters =
        Geolocator.distanceBetween(
      restaurantLatitude,
      restaurantLongitude,
      customerLatitude,
      customerLongitude,
    );

    return distanceMeters / 1000;
  }

  static bool isWithinServiceableRadius(
    double distanceKm,
  ) {
    return distanceKm <=
        _serviceableRadiusKm;
  }

  static double calculateLongDistanceCharge({
    required double distanceKm,
  }) {
    if (distanceKm <=
        _longDistanceFreeRadiusKm) {
      return 0;
    }

    return _longDistanceCharge;
  }

  static double get serviceableRadiusKm =>
      _serviceableRadiusKm;

  static double get longDistanceFreeRadiusKm =>
      _longDistanceFreeRadiusKm;

  static double get longDistanceCharge =>
      _longDistanceCharge;

  static BillSummaryModel calculateBill({
    required double itemsTotal,
    double couponDiscount = 0,
    String? couponCode,
    double distanceKm = 0,
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

    final double finalLongDistanceCharge =
        calculateLongDistanceCharge(
      distanceKm: distanceKm,
    );

    final double grandTotal =
        itemsTotal +
        finalDeliveryFee +
        finalLongDistanceCharge +
        _platformFee -
        safeCouponDiscount;

    return BillSummaryModel(
      itemsTotal: itemsTotal,
      deliveryFee: finalDeliveryFee,
      longDistanceCharge:
          finalLongDistanceCharge,
      platformFee: _platformFee,
      couponDiscount:
          safeCouponDiscount,
      grandTotal: grandTotal,
      couponCode:
          safeCouponDiscount > 0
              ? couponCode
              : null,
    );
  }
}
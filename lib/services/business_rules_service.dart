import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessRulesService {
  BusinessRulesService._();

  static final BusinessRulesService instance =
      BusinessRulesService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>>
      get _businessRulesRef {
    return _firestore
        .collection('app_settings')
        .doc('business_rules');
  }

  Future<Map<String, dynamic>> getBusinessRules() async {
    final snapshot =
        await _businessRulesRef.get();

    if (!snapshot.exists) {
      return {
        'deliveryFee': 30.0,
        'platformFee': 10.0,
        'freeDeliveryAbove': 0.0,
      };
    }

    final data =
        snapshot.data() ?? {};

    return {
      'deliveryFee':
          _numberValue(
        data['deliveryFee'],
        30.0,
      ),
      'platformFee':
          _numberValue(
        data['platformFee'],
        10.0,
      ),
      'freeDeliveryAbove':
          _numberValue(
        data['freeDeliveryAbove'],
        0.0,
      ),
    };
  }

  double _numberValue(
    dynamic value,
    double fallback,
  ) {
    if (value is num) {
      final number = value.toDouble();

      if (number.isFinite &&
          number >= 0) {
        return number;
      }
    }

    return fallback;
  }
}
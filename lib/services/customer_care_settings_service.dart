import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_care_settings_model.dart';

class CustomerCareSettingsService {
  CustomerCareSettingsService._();

  static final CustomerCareSettingsService instance =
      CustomerCareSettingsService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>>
      get _settingsReference =>
          _firestore
              .collection('app_settings')
              .doc('customer_care');

  Future<CustomerCareSettingsModel>
      getSettings() async {
    final snapshot =
        await _settingsReference.get();

    if (!snapshot.exists) {
      return const CustomerCareSettingsModel();
    }

    return CustomerCareSettingsModel.fromMap(
      snapshot.data() ?? {},
    );
  }

  Stream<CustomerCareSettingsModel>
      settingsStream() {
    return _settingsReference
        .snapshots()
        .map(
          (snapshot) {
            if (!snapshot.exists) {
              return const CustomerCareSettingsModel();
            }

            return CustomerCareSettingsModel.fromMap(
              snapshot.data() ?? {},
            );
          },
        );
  }
}
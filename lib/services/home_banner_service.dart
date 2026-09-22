import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBannerService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<Map<String, dynamic>?> getCurrentBanner() {
    return _firestore
        .collection('home_banners')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists ||
          snapshot.data() == null) {
        return null;
      }

      return snapshot.data();
    });
  }
}
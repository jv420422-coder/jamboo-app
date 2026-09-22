import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String get uid =>
      _auth.currentUser!.uid;

  // ============================================================
  // SUBMIT RESTAURANT RATING
  // ============================================================

  Future<void> submitRating({
    required RatingModel rating,
  }) async {
    // 1. Save restaurant rating
    await _firestore
        .collection("ratings")
        .doc(rating.ratingId)
        .set(rating.toMap());

    // 2. Mark order as rated
    await _firestore
        .collection("orders")
        .doc(rating.orderId)
        .update({
      "isRated": true,
      "rating": rating.rating,
    });

    // 3. Update restaurant average.
    //
    // If this fails, the customer's rating is still saved
    // and the order is still marked as rated.
    try {
      await updateRestaurantRating(
        restaurantId: rating.restaurantId,
      );
    } catch (e) {
      print(
        "RESTAURANT RATING UPDATE ERROR: $e",
      );
    }
  }

  // ============================================================
  // CHECK IF ORDER IS ALREADY RATED
  // ============================================================

  Future<bool> hasUserRatedOrder({
    required String orderId,
  }) async {
    final doc = await _firestore
        .collection("orders")
        .doc(orderId)
        .get();

    if (!doc.exists) {
      return false;
    }

    final data =
        doc.data() ?? {};

    return data["isRated"] == true;
  }

  // ============================================================
  // CALCULATE RESTAURANT AVERAGE
  // ============================================================

  Future<double> calculateAverageRating({
    required String restaurantId,
  }) async {
    final snapshot = await _firestore
        .collection("ratings")
        .where(
          "restaurantId",
          isEqualTo: restaurantId,
        )
        .get();

    if (snapshot.docs.isEmpty) {
      return 0.0;
    }

    double total = 0.0;
    int validRatings = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final value = data["rating"];

      if (value is num) {
        total += value.toDouble();
        validRatings++;
      }
    }

    if (validRatings == 0) {
      return 0.0;
    }

    return total / validRatings;
  }

  // ============================================================
  // UPDATE RESTAURANT RATING
  // ============================================================

  Future<void> updateRestaurantRating({
  required String restaurantId,
}) async {
  final snapshot = await _firestore
      .collection("ratings")
      .where(
        "restaurantId",
        isEqualTo: restaurantId,
      )
      .get();

  double total = 0.0;
  int validRatings = 0;

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final value = data["rating"];

    if (value is num) {
      total += value.toDouble();
      validRatings++;
    }
  }

  final average = validRatings == 0
      ? 0.0
      : total / validRatings;

  await _firestore
      .collection("restaurant_registrations")
      .doc(restaurantId)
      .set({
    "averageRating": average,
    "totalRatings": validRatings,
  }, SetOptions(merge: true));
}

  // ============================================================
  // SUBMIT DELIVERY PARTNER RATING
  // ============================================================

  Future<void> submitDeliveryPartnerRating({
    required String ratingId,
    required String orderId,
    required String orderNumber,
    required String deliveryPartnerId,
    required String deliveryPartnerName,
    required String customerId,
    required String customerName,
    required double rating,
    required String review,
  }) async {
    await _firestore
        .collection("delivery_partner_ratings")
        .doc(ratingId)
        .set({
      "ratingId": ratingId,
      "orderId": orderId,
      "orderNumber": orderNumber,
      "deliveryPartnerId":
          deliveryPartnerId,
      "deliveryPartnerName":
          deliveryPartnerName,
      "customerId": customerId,
      "customerName": customerName,
      "rating": rating,
      "review": review,
      "createdAt":
          FieldValue.serverTimestamp(),
    });
  }
}
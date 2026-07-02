import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/rating_model.dart';

class RatingService {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final String uid =
      FirebaseAuth.instance.currentUser!.uid;

Future<void> submitRating({
  required RatingModel rating,
}) async {

  await _firestore
      .collection("ratings")
      .doc(rating.ratingId)
      .set(rating.toMap());
      // Mark order as rated
await _firestore
    .collection("orders")
    .doc(rating.orderId)
    .update({
  "isRated": true,
});
await updateRestaurantRating(
  restaurantId: rating.restaurantId,
);

}
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
      doc.data() as Map<String, dynamic>;

  return data["isRated"] ?? false;

}
Future<double> calculateAverageRating({
  required String restaurantId,
}) async {

  final snapshot = await _firestore
      .collection("ratings")
      .where("restaurantId", isEqualTo: restaurantId)
      .get();

  if (snapshot.docs.isEmpty) {
    return 0;
  }

  double total = 0;

  for (final doc in snapshot.docs) {

    final data =
        doc.data();

    total +=
        (data["rating"] as num).toDouble();

  }

  return total / snapshot.docs.length;

}
Future<void> updateRestaurantRating({
  required String restaurantId,
}) async {

  final average =
      await calculateAverageRating(
    restaurantId: restaurantId,
  );

  final snapshot = await _firestore
      .collection("ratings")
      .where(
        "restaurantId",
        isEqualTo: restaurantId,
      )
      .get();

  await _firestore
      .collection("restaurants")
      .doc(restaurantId)
      .update({

    "averageRating": average,
    "totalRatings": snapshot.docs.length,

  });

}
}
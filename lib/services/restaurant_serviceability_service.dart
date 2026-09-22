import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RestaurantServiceabilityService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<double> getServiceableRadiusKm() async {
    final snapshot = await _firestore
        .collection('app_settings')
        .doc('business_rules')
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return 7;
    }

    final value = snapshot.data()!['serviceableRadiusKm'];

    if (value is num) {
      return value.toDouble();
    }

    return 7;
  }

  double calculateDistanceKm({
    required double customerLatitude,
    required double customerLongitude,
    required double restaurantLatitude,
    required double restaurantLongitude,
  }) {
    final distanceInMeters = Geolocator.distanceBetween(
      customerLatitude,
      customerLongitude,
      restaurantLatitude,
      restaurantLongitude,
    );

    return distanceInMeters / 1000;
  }

  bool isWithinServiceableRadius({
    required double customerLatitude,
    required double customerLongitude,
    required double restaurantLatitude,
    required double restaurantLongitude,
    required double radiusKm,
  }) {
    final distanceKm = calculateDistanceKm(
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      restaurantLatitude: restaurantLatitude,
      restaurantLongitude: restaurantLongitude,
    );

    return distanceKm <= radiusKm;
  }

  Future<bool> isRestaurantServiceable({
    required double customerLatitude,
    required double customerLongitude,
    required Map<String, dynamic> restaurantData,
  }) async {
    final latitude = restaurantData['latitude'];
    final longitude = restaurantData['longitude'];

    if (latitude is! num || longitude is! num) {
      return false;
    }

    final radiusKm = await getServiceableRadiusKm();

    return isWithinServiceableRadius(
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      restaurantLatitude: latitude.toDouble(),
      restaurantLongitude: longitude.toDouble(),
      radiusKm: radiusKm,
    );
  }
}
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String orderId;

  const LiveTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<LiveTrackingScreen> createState() =>
      _LiveTrackingScreenState();
}

class _LiveTrackingScreenState
    extends State<LiveTrackingScreen> {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  GoogleMapController? _mapController;

  StreamSubscription<DocumentSnapshot>?
      _orderSubscription;
      StreamSubscription<DocumentSnapshot>?
    _riderSubscription;

  Map<String, dynamic>? _order;

  final Set<Marker> _markers = {};

  bool _loading = true;
  double _remainingDistance = 0;

String _lastUpdated = "--";

String _riderName = "";

  LatLng _initialPosition =
      const LatLng(26.7606, 83.3732);

  @override
  void initState() {
    super.initState();

    _listenOrder();
  }

  void _listenOrder() {

    _orderSubscription = _firestore
        .collection("orders")
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {

      if (!snapshot.exists) return;

      _order =
          snapshot.data() as Map<String, dynamic>;

      _loadStaticMarkers();
    });
  }

  void _loadStaticMarkers() {

    _markers.clear();

    final restaurantLat =
        (_order?["restaurantLatitude"] ?? 0)
            .toDouble();

    final restaurantLng =
        (_order?["restaurantLongitude"] ?? 0)
            .toDouble();

    final customerLat =
        (_order?["customerLatitude"] ?? 0)
            .toDouble();

    final customerLng =
        (_order?["customerLongitude"] ?? 0)
            .toDouble();

    if (restaurantLat != 0 &&
        restaurantLng != 0) {

      _markers.add(

        Marker(

          markerId:
              const MarkerId("restaurant"),

          position: LatLng(
            restaurantLat,
            restaurantLng,
          ),

          infoWindow: InfoWindow(
            title:
                _order?["restaurantName"] ?? "",
            snippet: "Restaurant",
          ),

        ),

      );

      _initialPosition = LatLng(
        restaurantLat,
        restaurantLng,
      );
    }

    if (customerLat != 0 &&
        customerLng != 0) {

      _markers.add(

        Marker(

          markerId:
              const MarkerId("customer"),

          position: LatLng(
            customerLat,
            customerLng,
          ),

          infoWindow: const InfoWindow(
            title: "Delivery Address",
          ),

        ),

      );
    }
    _listenRiderLocation();
    if (mounted) {

      setState(() {
        _loading = false;
      });

    }
  }
  void _listenRiderLocation() {

  final riderId =
      (_order?["deliveryPartnerId"] ?? "")
          .toString();

  if (riderId.isEmpty) return;

  _riderSubscription?.cancel();

  _riderSubscription = _firestore
      .collection("delivery_partners")
      .doc(riderId)
      .snapshots()
      .listen((snapshot) {

    if (!snapshot.exists) return;

    final rider = snapshot.data()!;
    _riderName = rider["fullName"] ?? "";

    final latitude =
        (rider["latitude"] ?? 0)
            .toDouble();

    final longitude =
        (rider["longitude"] ?? 0)
            .toDouble();
            final customerLat =
    (_order?["customerLatitude"] ?? 0)
        .toDouble();

final customerLng =
    (_order?["customerLongitude"] ?? 0)
        .toDouble();

_remainingDistance =
    _calculateDistance(
      latitude,
      longitude,
      customerLat,
      customerLng,
    );

_lastUpdated =
    DateTime.now().hour
        .toString()
        .padLeft(2, "0") +
    ":" +
    DateTime.now().minute
        .toString()
        .padLeft(2, "0");

    if (latitude == 0 || longitude == 0) {
      return;
    }

    _markers.removeWhere(
      (marker) =>
          marker.markerId.value == "rider",
    );

    _markers.add(
      Marker(
        markerId: const MarkerId("rider"),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title:
              rider["fullName"] ??
              "Delivery Partner",
        ),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    );

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(latitude, longitude),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  });
}
double _calculateDistance(
  double startLat,
  double startLng,
  double endLat,
  double endLng,
) {
  const earthRadius = 6371;

  final dLat =
      _degreeToRadian(endLat - startLat);

  final dLng =
      _degreeToRadian(endLng - startLng);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreeToRadian(startLat)) *
          cos(_degreeToRadian(endLat)) *
          sin(dLng / 2) *
          sin(dLng / 2);

  final c =
      2 * atan2(
        sqrt(a),
        sqrt(1 - a),
      );

  return earthRadius * c;
}

double _degreeToRadian(
  double degree,
) {
  return degree * pi / 180;
}

  @override
  void dispose() {

    _orderSubscription?.cancel();

    _mapController?.dispose();

    _riderSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF5F0FF),

      appBar: AppBar(

        backgroundColor:
            const Color(0xFFF5F0FF),

        elevation: 0,

        title: const Text(
          "Live Order Tracking",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Stack(

              children: [

                GoogleMap(

                  initialCameraPosition:
                      CameraPosition(
                    target: _initialPosition,
                    zoom: 15,
                  ),

                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  compassEnabled: true,

                  markers: _markers,

                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,

                  child: Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: .08,
                          ),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Text(
                          _order?["restaurantName"] ?? "",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Order : ${_order?["orderNumber"] ?? ""}",
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Status : ${_order?["orderStatus"] ?? ""}",
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Row(
      children: const [

        Icon(
          Icons.delivery_dining,
          color: Colors.deepPurple,
        ),

        SizedBox(width: 8),

        Text(
          "Delivery Partner",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),

    const SizedBox(height: 8),

    Text(
      _riderName.isEmpty
          ? "Searching rider..."
          : _riderName,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),

    const SizedBox(height: 8),

    Text(
      "Remaining Distance : ${_remainingDistance.toStringAsFixed(2)} km",
    ),

    const SizedBox(height: 4),

    Text(
      "Last Updated : $_lastUpdated",
      style: const TextStyle(
        color: Colors.grey,
      ),
    ),
  ],
),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
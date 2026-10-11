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

  String _listeningRiderId = "";

  // Custom rider PNG icon
  BitmapDescriptor? _riderIcon;

  // Latest rider location
  Map<String, dynamic>? _latestRiderLocation;

  LatLng _initialPosition =
      const LatLng(26.7606, 83.3732);

  @override
  void initState() {
    super.initState();

    _loadRiderIcon();
    _listenOrder();
  }

  // --------------------------------------------------
  // LOAD RIDER PNG
  // --------------------------------------------------

  Future<void> _loadRiderIcon() async {
    try {
      final icon =
          await BitmapDescriptor.asset(
        const ImageConfiguration(
          size: Size(48, 48),
        ),
        'assets/images/delivery_boy.png',
        width: 48,
        height: 48,
      );

      if (!mounted) return;

      _riderIcon = icon;

      // If rider location arrived before icon loaded,
      // add the rider marker now.
      if (_latestRiderLocation != null) {
        _updateRiderLocation(
          _latestRiderLocation!,
        );
      } else {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        "JAMBOO RIDER ICON ERROR: $e",
      );
    }
  }

  // --------------------------------------------------
  // ORDER LISTENER
  // --------------------------------------------------

  void _listenOrder() {
    _orderSubscription = _firestore
        .collection("orders")
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data();

      if (data == null) {
        return;
      }

      _order = data;

      _startRiderListenerIfNeeded();

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  // --------------------------------------------------
  // RIDER LISTENER
  // --------------------------------------------------

  void _startRiderListenerIfNeeded() {
    final riderId =
        (_order?["deliveryPartnerId"] ?? "")
            .toString()
            .trim();

    if (riderId.isEmpty) {
      _riderSubscription?.cancel();
      _riderSubscription = null;
      _listeningRiderId = "";
      _riderName = "";
      return;
    }

    if (_listeningRiderId == riderId &&
        _riderSubscription != null) {
      return;
    }

    _riderSubscription?.cancel();

    _listeningRiderId = riderId;

    _riderSubscription = _firestore
        .collection(
          "delivery_partner_locations",
        )
        .doc(riderId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          debugPrint(
            "JAMBOO RIDER LOCATION ERROR: "
            "Location document does not exist: $riderId",
          );
          return;
        }

        final riderLocation =
            snapshot.data();

        if (riderLocation == null) {
          debugPrint(
            "JAMBOO RIDER LOCATION ERROR: "
            "Location data is null",
          );
          return;
        }

        debugPrint(
          "JAMBOO RIDER LOCATION DATA: "
          "$riderLocation",
        );

        _updateRiderLocation(
          riderLocation,
        );
      },
      onError: (error) {
        debugPrint(
          "JAMBOO RIDER LOCATION FIRESTORE ERROR: "
          "$error",
        );
      },
    );
  }

  // --------------------------------------------------
  // UPDATE RIDER LOCATION
  // --------------------------------------------------

  void _updateRiderLocation(
    Map<String, dynamic> rider,
  ) {
    // Save latest location
    _latestRiderLocation = rider;

    _riderName =
        (_order?["deliveryPartnerName"] ?? "")
            .toString();

    final latitude =
        (rider["latitude"] ?? 0)
            .toDouble();

    final longitude =
        (rider["longitude"] ?? 0)
            .toDouble();

    if (latitude == 0 ||
        longitude == 0) {
      if (mounted) {
        setState(() {});
      }

      return;
    }

    // ------------------------------------------------
    // DISTANCE FROM RIDER TO CUSTOMER
    // ------------------------------------------------

    final customerLat =
        (_order?["customerLatitude"] ?? 0)
            .toDouble();

    final customerLng =
        (_order?["customerLongitude"] ?? 0)
            .toDouble();

    if (customerLat != 0 &&
        customerLng != 0) {
      _remainingDistance =
          _calculateDistance(
        latitude,
        longitude,
        customerLat,
        customerLng,
      );
    }

    // ------------------------------------------------
    // LAST UPDATED
    // ------------------------------------------------

    final lastLocationUpdate =
        rider["lastLocationUpdate"];

    if (lastLocationUpdate
        is Timestamp) {
      final date =
          lastLocationUpdate.toDate();

      _lastUpdated =
          "${date.hour.toString().padLeft(2, "0")}:"
          "${date.minute.toString().padLeft(2, "0")}:"
          "${date.second.toString().padLeft(2, "0")}";
    } else {
      _lastUpdated =
          "${DateTime.now().hour.toString().padLeft(2, "0")}:"
          "${DateTime.now().minute.toString().padLeft(2, "0")}:"
          "${DateTime.now().second.toString().padLeft(2, "0")}";
    }

    // ------------------------------------------------
    // ONLY RIDER MARKER
    // ------------------------------------------------

    _markers.removeWhere(
      (marker) =>
          marker.markerId.value == "rider",
    );

    if (_riderIcon != null) {
      _markers.add(
        Marker(
          markerId:
              const MarkerId("rider"),
          position: LatLng(
            latitude,
            longitude,
          ),
          infoWindow: InfoWindow(
            title: _riderName.isEmpty
                ? "Delivery Partner"
                : _riderName,
          ),
          icon: _riderIcon!,
          anchor:
              const Offset(0.5, 1.0),
        ),
      );
    }

    // ------------------------------------------------
    // MOVE MAP TO RIDER
    // ------------------------------------------------

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            latitude,
            longitude,
          ),
        ),
      );
    } else {
      _initialPosition = LatLng(
        latitude,
        longitude,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  // --------------------------------------------------
  // DISTANCE CALCULATION
  // --------------------------------------------------

  double _calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadius = 6371;

    final dLat =
        _degreeToRadian(
      endLat - startLat,
    );

    final dLng =
        _degreeToRadian(
      endLng - startLng,
    );

    final a =
        sin(dLat / 2) *
            sin(dLat / 2) +
        cos(
              _degreeToRadian(
                startLat,
              ),
            ) *
            cos(
              _degreeToRadian(
                endLat,
              ),
            ) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c =
        2 *
            atan2(
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

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _riderSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
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
                    target:
                        _initialPosition,
                    zoom: 17,
                  ),

                  // Customer's blue location dot OFF
                  myLocationEnabled: false,

                  // Current-location button OFF
                  myLocationButtonEnabled:
                      false,

                  zoomControlsEnabled:
                      false,

                  compassEnabled: true,

                  // ONLY rider marker
                  markers: _markers,

                  onMapCreated:
                      (controller) {
                    _mapController =
                        controller;

                    // If rider location is already
                    // available, move camera to it.
                    final rider =
                        _latestRiderLocation;

                    if (rider != null) {
                      final latitude =
                          (rider["latitude"] ??
                                  0)
                              .toDouble();

                      final longitude =
                          (rider["longitude"] ??
                                  0)
                              .toDouble();

                      if (latitude != 0 &&
                          longitude != 0) {
                        controller.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(
                              latitude,
                              longitude,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),

                // ------------------------------------------------
                // BOTTOM ORDER INFORMATION CARD
                // ------------------------------------------------

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: .08,
                          ),
                          blurRadius: 15,
                          offset:
                              const Offset(
                            0,
                            6,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          _order?[
                                  "restaurantName"] ??
                              "",
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          "Order : ${_order?["orderNumber"] ?? ""}",
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          "Status : ${_order?["orderStatus"] ?? ""}",
                          style:
                              const TextStyle(
                            color:
                                Colors.deepPurple,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .delivery_dining,
                              color: Colors
                                  .deepPurple,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              "Delivery Partner",
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          _riderName.isEmpty
                              ? "Searching rider..."
                              : _riderName,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          "Remaining Distance : ${_remainingDistance.toStringAsFixed(2)} km",
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          "Last Updated : $_lastUpdated",
                          style:
                              const TextStyle(
                            color: Colors.grey,
                          ),
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
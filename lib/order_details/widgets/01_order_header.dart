import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderHeader extends StatefulWidget {
  final Color statusColor;
  final IconData statusIcon;
  final String statusTitle;
  final String statusMessage;
  final Map<String, dynamic> orderData;

  const OrderHeader({
    super.key,
    required this.statusColor,
    required this.statusIcon,
    required this.statusTitle,
    required this.statusMessage,
    required this.orderData,
  });

  @override
  State<OrderHeader> createState() =>
      _OrderHeaderState();
}

class _OrderHeaderState
    extends State<OrderHeader> {
  Timer? _timer;

  DateTime? _countdownTarget;

  String _countdownText = "";

  String _etaTitle = "";
  String _etaMessage = "";
  String _etaCardTitle = "";
  String _etaCardMessage = "";

  IconData _etaCardIcon =
      Icons.timer_outlined;

  String _lastRiderId = "";

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _riderSubscription;

  @override
  void initState() {
    super.initState();

    _setupEta();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _updateCountdown();
      },
    );
  }

  @override
  void didUpdateWidget(
    covariant OrderHeader oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldStatus =
        _normalizeStatus(
      oldWidget.orderData["orderStatus"] ??
          oldWidget.orderData["status"] ??
          "",
    );

    final newStatus =
        _normalizeStatus(
      widget.orderData["orderStatus"] ??
          widget.orderData["status"] ??
          "",
    );

    final oldRiderId =
        (oldWidget.orderData[
                    "deliveryPartnerId"] ??
                "")
            .toString();

    final newRiderId =
        (widget.orderData[
                    "deliveryPartnerId"] ??
                "")
            .toString();

    if (oldStatus != newStatus ||
        oldRiderId != newRiderId) {
      _setupEta();
    }
  }

  String _normalizeStatus(
    dynamic value,
  ) {
    return value
        .toString()
        .toLowerCase()
        .replaceAll(" ", "")
        .replaceAll("_", "");
  }

  DateTime? _timestampToDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  void _setupEta() {
    _riderSubscription?.cancel();
    _riderSubscription = null;

    _countdownTarget = null;
    _countdownText = "";

    _etaTitle = "";
    _etaMessage = "";
    _etaCardTitle = "";
    _etaCardMessage = "";
    _etaCardIcon = Icons.timer_outlined;

    final status =
        _normalizeStatus(
      widget.orderData["orderStatus"] ??
          widget.orderData["status"] ??
          "",
    );

    if (status == "preparing") {
      _setupPreparationEta();
      return;
    }

    if (status == "ready") {
      _setupReadyEta();
      return;
    }

    if (status == "pickedup" ||
        status == "outfordelivery") {
      _setupDeliveryEta();
      return;
    }

    if (status == "accepted" ||
        status == "orderaccepted" ||
        status == "received" ||
        status == "pending") {
      _etaTitle = "Order Status";

      _etaMessage =
          "Restaurant has accepted your order.";

      _etaCardTitle =
          "Order accepted";

      _etaCardMessage =
          "Please wait, we'll update you shortly.";

      _etaCardIcon =
          Icons.check_circle_outline;

      return;
    }

    if (status == "delivered") {
      _etaTitle = "Order Delivered";

      _etaMessage =
          "Your order has been delivered successfully.";

      _etaCardTitle =
          "Order delivered";

      _etaCardMessage =
          "Thank you for ordering with Jamboo.";

      _etaCardIcon =
          Icons.check_circle;

      return;
    }

    if (status == "cancelled" ||
        status == "rejected") {
      _etaTitle = "Order Status";

      _etaMessage =
          "This order is no longer active.";

      _etaCardTitle =
          "Order closed";

      _etaCardMessage =
          "No further delivery updates are available.";

      _etaCardIcon =
          Icons.info_outline;

      return;
    }
  }

  void _setupPreparationEta() {
    final estimatedReadyAt =
        _timestampToDate(
      widget.orderData["estimatedReadyAt"],
    );

    _etaTitle =
        "Estimated Preparation";

    _etaMessage =
        "Restaurant is preparing your order.";

    if (estimatedReadyAt == null) {
      _etaCardTitle =
          "Preparation in progress";

      _etaCardMessage =
          "Your restaurant is preparing the order.";

      _etaCardIcon =
          Icons.restaurant_outlined;

      return;
    }

    _countdownTarget =
        estimatedReadyAt;

    _etaCardTitle =
        "Estimated Preparation";

    _etaCardMessage =
        "Please wait while your order is being prepared.";

    _etaCardIcon =
        Icons.timer_outlined;

    _updateCountdown();
  }

  void _setupReadyEta() {
    final estimatedReadyAt =
        _timestampToDate(
      widget.orderData["estimatedReadyAt"],
    );

    _etaTitle =
        "Order Ready";

    _etaMessage =
        "Your order is ready for pickup.";

    if (estimatedReadyAt == null) {
      _etaCardTitle =
          "Ready for pickup";

      _etaCardMessage =
          "Your delivery partner will pick up the order shortly.";

      _etaCardIcon =
          Icons.delivery_dining;

      return;
    }

    _countdownTarget =
        estimatedReadyAt;

    _etaCardTitle =
        "Estimated Delivery";

    _etaCardMessage =
        "Your order is ready and waiting for pickup.";

    _etaCardIcon =
        Icons.timer_outlined;

    _updateCountdown();
  }

  void _setupDeliveryEta() {
    final riderId =
        (widget.orderData[
                    "deliveryPartnerId"] ??
                "")
            .toString();

    _etaTitle =
        "Estimated Delivery";

    _etaMessage =
        "Rider is on the way.";

    if (riderId.isEmpty) {
      _etaCardTitle =
          "Delivery Partner";

      _etaCardMessage =
          "Your delivery partner is being assigned.";

      _etaCardIcon =
          Icons.delivery_dining;

      return;
    }

    _etaCardTitle =
        "Estimated Delivery";

    _etaCardMessage =
        "Rider is on the way.";

    _etaCardIcon =
        Icons.delivery_dining;

    if (_lastRiderId == riderId &&
        _riderSubscription != null) {
      return;
    }

    _lastRiderId = riderId;

    _riderSubscription =
        FirebaseFirestore.instance
            .collection("delivery_partners")
            .doc(riderId)
            .snapshots()
            .listen((snapshot) {
      if (!snapshot.exists) {
        return;
      }

      final rider =
          snapshot.data();

      if (rider == null) {
        return;
      }

      final riderLatitude =
          _toDouble(
        rider["latitude"],
      );

      final riderLongitude =
          _toDouble(
        rider["longitude"],
      );

      final customerLatitude =
          _toDouble(
        widget.orderData[
            "customerLatitude"],
      );

      final customerLongitude =
          _toDouble(
        widget.orderData[
            "customerLongitude"],
      );

      if (riderLatitude == 0 ||
          riderLongitude == 0 ||
          customerLatitude == 0 ||
          customerLongitude == 0) {
        return;
      }

      final distanceKm =
          _calculateDistanceKm(
        riderLatitude,
        riderLongitude,
        customerLatitude,
        customerLongitude,
      );

      final estimatedMinutes =
          _calculateDeliveryMinutes(
        distanceKm,
      );

      _countdownTarget =
          DateTime.now().add(
        Duration(
          minutes: estimatedMinutes,
        ),
      );

      _etaTitle =
          "Estimated Delivery";

      _etaMessage =
          "Rider is on the way.";

      _etaCardTitle =
          "Estimated Delivery";

      _etaCardMessage =
          "Rider is on the way.";

      _etaCardIcon =
          Icons.delivery_dining;

      _updateCountdown();
    });
  }

  double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? "",
        ) ??
        0;
  }

  double _calculateDistanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadius = 6371.0;

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

  int _calculateDeliveryMinutes(
    double distanceKm,
  ) {
    if (distanceKm <= 0.1) {
      return 2;
    }

    const averageSpeedKmPerHour =
        20.0;

    const roadDistanceFactor =
        1.3;

    final roadDistance =
        distanceKm *
            roadDistanceFactor;

    final minutes =
        (roadDistance /
                averageSpeedKmPerHour) *
            60;

    final rounded =
        minutes.ceil();

    if (rounded < 2) {
      return 2;
    }

    if (rounded > 60) {
      return 60;
    }

    return rounded;
  }

  void _updateCountdown() {
    if (!mounted) return;

    if (_countdownTarget == null) {
      if (_countdownText.isNotEmpty) {
        setState(() {
          _countdownText = "";
        });
      }

      return;
    }

    final remaining =
        _countdownTarget!
            .difference(
      DateTime.now(),
    );

    if (remaining.inSeconds <= 0) {
      if (_countdownText !=
          "Arriving shortly") {
        setState(() {
          _countdownText =
              "Arriving shortly";
        });
      }

      return;
    }

    final totalSeconds =
        remaining.inSeconds;

    final hours =
        totalSeconds ~/ 3600;

    final minutes =
        (totalSeconds % 3600) ~/ 60;

    final seconds =
        totalSeconds % 60;

    String text;

    if (hours > 0) {
      text =
          "${hours.toString().padLeft(2, '0')}:"
          "${minutes.toString().padLeft(2, '0')}:"
          "${seconds.toString().padLeft(2, '0')}";
    } else {
      text =
          "${minutes.toString().padLeft(2, '0')}:"
          "${seconds.toString().padLeft(2, '0')}";
    }

    if (text != _countdownText) {
      setState(() {
        _countdownText = text;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _riderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final showCountdown =
        _countdownText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: widget.statusColor,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: widget.statusColor
                .withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "🚚 Your Order",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Row(
            children: [
              Icon(
                widget.statusIcon,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  widget.statusTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            widget.statusMessage,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),

          if (_etaMessage.isNotEmpty) ...[
            const SizedBox(
              height: 16,
            ),

            Text(
              _etaMessage,
              style: const TextStyle(
                color: Colors.white,
                height: 1.45,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],

          if (_etaCardTitle.isNotEmpty) ...[
            const SizedBox(
              height: 20,
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    _etaCardIcon,
                    color: Colors.white,
                    size: 26,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _etaCardTitle,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        if (showCountdown)
                          Text(
                            "Approx. $_countdownText",
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            _etaCardMessage,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 15,
                              height: 1.35,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
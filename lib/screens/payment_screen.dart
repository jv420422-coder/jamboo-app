import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import 'order_details_screen.dart';
import '../services/billing_service.dart';
import 'saved_addresses_screen.dart';
import '../widgets/order_placing_overlay.dart';

class PaymentScreen extends StatefulWidget {
  final bool couponApplied;
  final String? couponCode;
  final double couponDiscount;

  const PaymentScreen({
    super.key,
    required this.couponApplied,
    this.couponCode,
    required this.couponDiscount,
  });

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState
    extends State<PaymentScreen> {
  final CartService _cartService =
      CartService();

  final OrderService _orderService =
      OrderService();

  late Razorpay _razorpay;

  String selectedPayment = "COD";

  bool isLoading = false;

  // ------------------------------------------------------------
  // Razorpay payment state
  // ------------------------------------------------------------

  String? _pendingPaymentId;
  String? _pendingRazorpayOrderId;
  OrderModel? _pendingOrder;

  bool _loadingOverlayShown = false;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );

    _loadBusinessRules();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Business rules
  // ------------------------------------------------------------

  Future<void> _loadBusinessRules() async {
    await BillingService.loadBusinessRules();

    if (!mounted) return;

    setState(() {
      if (!BillingService.codEnabled &&
          selectedPayment == "COD") {
        selectedPayment = "UPI";
      }
    });
  }

  // ------------------------------------------------------------
  // Razorpay callbacks
  // ------------------------------------------------------------

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {
    final paymentId =
        response.paymentId;

    final razorpayOrderId =
        response.orderId;

    final signature =
        response.signature;

    if (paymentId == null ||
        paymentId.trim().isEmpty ||
        razorpayOrderId == null ||
        razorpayOrderId.trim().isEmpty ||
        signature == null ||
        signature.trim().isEmpty) {
      await _handleOnlinePaymentFailure(
        "Payment response is incomplete. Please try again.",
      );
      return;
    }

    final pendingPaymentId =
        _pendingPaymentId;

    final pendingOrder =
        _pendingOrder;

    final expectedRazorpayOrderId =
        _pendingRazorpayOrderId;

    if (pendingPaymentId == null ||
        pendingPaymentId.trim().isEmpty ||
        pendingOrder == null ||
        expectedRazorpayOrderId == null ||
        expectedRazorpayOrderId.trim().isEmpty) {
      await _handleOnlinePaymentFailure(
        "Payment session expired. Please try again.",
      );
      return;
    }

    if (razorpayOrderId !=
        expectedRazorpayOrderId) {
      await _handleOnlinePaymentFailure(
        "Payment order mismatch. Please try again.",
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    _showLoadingOverlay();

    try {
      // --------------------------------------------------------
      // 1. Verify payment on Firebase backend
      // --------------------------------------------------------

      await _orderService
          .verifyRazorpayPayment(
        paymentId:
            pendingPaymentId,
        razorpayPaymentId:
            paymentId,
        razorpayOrderId:
            razorpayOrderId,
        razorpaySignature:
            signature,
      );

      // --------------------------------------------------------
      // 2. Create the actual Jamboo order only AFTER
      //    successful backend verification.
      // --------------------------------------------------------

      await _orderService.placeOrder(
        pendingOrder,
        couponCode:
            widget.couponApplied
                ? widget.couponCode
                : null,
        paymentIntentId:
            pendingPaymentId,
      );

      // --------------------------------------------------------
      // 3. Clear cart
      // --------------------------------------------------------

      try {
        await _cartService.clearCart();
      } catch (_) {
        // Order is already successfully created.
      }

      _hideLoadingOverlay();

      if (!mounted) return;

      // --------------------------------------------------------
      // 4. Open order details
      // --------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OrderDetailsScreen(
            order: pendingOrder,
          ),
        ),
      );

      _clearPendingPayment();
    } catch (e) {
      _hideLoadingOverlay();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _cleanErrorMessage(e),
          ),
          duration:
              const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handlePaymentError(
    PaymentFailureResponse response,
  ) async {
    final message =
        response.message ??
            "Payment failed. Please try again.";

    await _handleOnlinePaymentFailure(
      message,
    );
  }

  Future<void> _handleExternalWallet(
    ExternalWalletResponse response,
  ) async {
    await _handleOnlinePaymentFailure(
      "External wallet payment was selected. Please try again.",
    );
  }

  Future<void> _handleOnlinePaymentFailure(
    String message,
  ) async {
    _hideLoadingOverlay();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    _clearPendingPayment();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        duration:
            const Duration(seconds: 4),
      ),
    );
  }

  void _clearPendingPayment() {
    _pendingPaymentId = null;
    _pendingRazorpayOrderId = null;
    _pendingOrder = null;
  }

  // ------------------------------------------------------------
  // Loading overlay helpers
  // ------------------------------------------------------------

  void _showLoadingOverlay() {
    if (!mounted ||
        _loadingOverlayShown) {
      return;
    }

    _loadingOverlayShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const OrderPlacingOverlay(),
    );
  }

  void _hideLoadingOverlay() {
    if (!mounted ||
        !_loadingOverlayShown) {
      return;
    }

    _loadingOverlayShown = false;

    Navigator.of(context).pop();
  }

  // ------------------------------------------------------------
  // Error message helper
  // ------------------------------------------------------------

  String _cleanErrorMessage(
    Object error,
  ) {
    final message =
        error.toString();

    if (message.startsWith(
      "Exception: ",
    )) {
      return message.substring(
        "Exception: ".length,
      );
    }

    return message;
  }

  // ------------------------------------------------------------
  // Address validation
  // ------------------------------------------------------------

  bool _isValidAddress(
    Map<String, dynamic>? address,
  ) {
    if (address == null) {
      return false;
    }

    final fullName =
        (address["fullName"] ?? "")
            .toString()
            .trim();

    final phone =
        (address["phone"] ?? "")
            .toString()
            .trim();

    final fullAddress =
        (address["address"] ?? "")
            .toString()
            .trim();

    final city =
        (address["city"] ?? "")
            .toString()
            .trim();

    final state =
        (address["state"] ?? "")
            .toString()
            .trim();

    final pincode =
        (address["pincode"] ?? "")
            .toString()
            .trim();

    final latitude =
        (address["latitude"] as num?)
            ?.toDouble();

    final longitude =
        (address["longitude"] as num?)
            ?.toDouble();

    return fullName.isNotEmpty &&
        phone.isNotEmpty &&
        fullAddress.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        pincode.isNotEmpty &&
        latitude != null &&
        longitude != null;
  }

  // ------------------------------------------------------------
  // Address required popup
  // ------------------------------------------------------------

  Future<void>
      _showAddressRequiredPopup() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.location_on,
                color:
                    Colors.deepPurple,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Delivery Address Required",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            "Please add or select a delivery address before placing your order.",
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text("Cancel"),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepPurple,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SavedAddressesScreen(
                      isCheckoutMode: true,
                    ),
                  ),
                );
              },
              child:
                  const Text("Add Address"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Serviceability popup
  // ------------------------------------------------------------

  Future<void>
      _showServiceabilityPopup(
    double distanceKm,
  ) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.location_off,
                color:
                    Colors.redAccent,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Delivery Not Available",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "This restaurant is ${distanceKm.toStringAsFixed(1)} km "
            "away and is outside our current delivery area.",
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // COD unavailable popup
  // ------------------------------------------------------------

  Future<void>
      _showCodUnavailablePopup() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.money_off,
                color:
                    Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Cash on Delivery Unavailable",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            "Cash on Delivery is not currently available. Please select another payment method.",
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Get selected address
  // ------------------------------------------------------------

  Future<Map<String, dynamic>?>
      _getSelectedAddress(
    String uid,
  ) async {
    final snapshot =
        await FirebaseFirestore
            .instance
            .collection("users")
            .doc(uid)
            .collection("addresses")
            .where(
              "selectedForCheckout",
              isEqualTo: true,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final data =
        snapshot.docs.first.data();

    return {
      "fullName":
          data["fullName"] ?? "",
      "phone":
          data["phone"] ?? "",
      "address":
          data["address"] ?? "",
      "landmark":
          data["landmark"] ?? "",
      "city":
          data["city"] ?? "",
      "state":
          data["state"] ?? "",
      "pincode":
          data["pincode"] ?? "",
      "type":
          data["type"] ?? "",
      "latitude":
          (data["latitude"] ?? 0)
              .toDouble(),
      "longitude":
          (data["longitude"] ?? 0)
              .toDouble(),
    };
  }

  // ------------------------------------------------------------
  // Get distance
  // ------------------------------------------------------------

  Future<double?> _getDistanceKm({
    required String restaurantId,
    required Map<String, dynamic> address,
  }) async {
    final restaurantSnapshot =
        await FirebaseFirestore
            .instance
            .collection(
              "restaurant_registrations",
            )
            .doc(restaurantId)
            .get();

    if (!restaurantSnapshot.exists) {
      return null;
    }

    final restaurantData =
        restaurantSnapshot.data() ?? {};

    final restaurantLatitude =
        (restaurantData["latitude"]
                as num?)
            ?.toDouble();

    final restaurantLongitude =
        (restaurantData["longitude"]
                as num?)
            ?.toDouble();

    final customerLatitude =
        (address["latitude"] as num?)
            ?.toDouble();

    final customerLongitude =
        (address["longitude"] as num?)
            ?.toDouble();

    if (restaurantLatitude == null ||
        restaurantLongitude == null ||
        customerLatitude == null ||
        customerLongitude == null) {
      return null;
    }

    return BillingService
        .calculateDistanceKm(
      restaurantLatitude:
          restaurantLatitude,
      restaurantLongitude:
          restaurantLongitude,
      customerLatitude:
          customerLatitude,
      customerLongitude:
          customerLongitude,
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentUser =
        FirebaseAuth
            .instance
            .currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please login to continue.",
          ),
        ),
      );
    }

    final uid =
        currentUser.uid;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "💳 Payment",
          style: TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot>(
        stream:
            FirebaseFirestore
                .instance
                .collection("users")
                .doc(uid)
                .collection("addresses")
                .where(
                  "selectedForCheckout",
                  isEqualTo: true,
                )
                .limit(1)
                .snapshots(),
        builder:
            (context,
                addressSnapshot) {
          if (!addressSnapshot
              .hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          Map<String, dynamic>?
              address;

          if (addressSnapshot
              .data!
              .docs
              .isNotEmpty) {
            address =
                addressSnapshot
                        .data!
                        .docs
                        .first
                        .data()
                    as Map<String,
                        dynamic>;
          }

          final bool
              hasValidAddress =
              _isValidAddress(
            address,
          );

          return StreamBuilder<
              QuerySnapshot>(
            stream:
                _cartService
                    .cartStream(),
            builder:
                (
              context,
              cartSnapshot,
            ) {
              if (!cartSnapshot
                  .hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final cartDocs =
                  cartSnapshot
                      .data!
                      .docs;

              if (cartDocs.isEmpty) {
                return const Center(
                  child: Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                );
              }

              double subtotal = 0;

              String restaurantId =
                  "";

              for (final doc
                  in cartDocs) {
                final data =
                    doc.data()
                        as Map<String,
                            dynamic>;

                subtotal +=
                    ((data["price"]
                                as num)
                            .toDouble()) *
                        ((data["quantity"]
                                as num)
                            .toInt());

                if (restaurantId
                    .isEmpty) {
                  restaurantId =
                      (data[
                                  "restaurantId"] ??
                              "")
                          .toString();
                }
              }

              if (!hasValidAddress ||
                  restaurantId
                      .isEmpty) {
                return _buildPaymentContent(
                  context: context,
                  address: address,
                  hasValidAddress:
                      hasValidAddress,
                  subtotal: subtotal,
                  cartDocs: cartDocs,
                  restaurantId:
                      restaurantId,
                  distanceKm: null,
                  bill: null,
                  uid: uid,
                );
              }

              return FutureBuilder<
                  double?>(
                future:
                    _getDistanceKm(
                  restaurantId:
                      restaurantId,
                  address:
                      address!,
                ),
                builder: (
                  context,
                  distanceSnapshot,
                ) {
                  final double?
                      distanceKm =
                      distanceSnapshot
                          .data;

                  if (distanceSnapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  final bill =
                      distanceKm ==
                              null
                          ? null
                          : BillingService
                              .calculateBill(
                              itemsTotal:
                                  subtotal,
                              couponDiscount:
                                  widget
                                          .couponApplied
                                      ? widget
                                          .couponDiscount
                                      : 0,
                              couponCode:
                                  widget
                                      .couponCode,
                              distanceKm:
                                  distanceKm,
                            );

                  return _buildPaymentContent(
                    context: context,
                    address: address,
                    hasValidAddress:
                        hasValidAddress,
                    subtotal: subtotal,
                    cartDocs: cartDocs,
                    restaurantId:
                        restaurantId,
                    distanceKm:
                        distanceKm,
                    bill: bill,
                    uid: uid,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // PAYMENT CONTENT
  // ------------------------------------------------------------

  Widget _buildPaymentContent({
    required BuildContext context,
    required Map<String, dynamic>? address,
    required bool hasValidAddress,
    required double subtotal,
    required List<
            QueryDocumentSnapshot>
        cartDocs,
    required String restaurantId,
    required double? distanceKm,
    required dynamic bill,
    required String uid,
  }) {
    final bool isServiceable =
        distanceKm != null &&
            BillingService
                .isWithinServiceableRadius(
              distanceKm,
            );

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // ADDRESS
          // ------------------------------------------------------

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color:
                          hasValidAddress
                              ? Colors
                                  .deepPurple
                              : Colors
                                  .redAccent,
                    ),
                    const SizedBox(
                        width: 8),
                    const Text(
                      "Deliver To",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                    height: 10),
                if (hasValidAddress) ...[
                  Text(
                    address!["fullName"]
                            ?.toString() ??
                        "",
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  Text(
                    address["phone"]
                            ?.toString() ??
                        "",
                  ),
                  const SizedBox(
                      height: 5),
                  Text(
                    address["address"]
                            ?.toString() ??
                        "",
                  ),
                  Text(
                    "${address["city"]}, "
                    "${address["state"]} - "
                    "${address["pincode"]}",
                  ),
                ] else ...[
                  const Text(
                    "No delivery address selected",
                    style:
                        TextStyle(
                      color:
                          Colors.redAccent,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                      height: 6),
                  const Text(
                    "Please add a delivery address to place your order.",
                    style:
                        TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                  const SizedBox(
                      height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SavedAddressesScreen(
                            isCheckoutMode:
                                true,
                          ),
                        ),
                      );
                    },
                    child:
                        const Text(
                      "Add / Select Address",
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
              height: 20),

          // ------------------------------------------------------
          // DISTANCE
          // ------------------------------------------------------

          if (distanceKm != null)
            Container(
              width:
                  double.infinity,
              margin:
                  const EdgeInsets.only(
                bottom: 20,
              ),
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color: isServiceable
                    ? Colors.white
                    : Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isServiceable
                        ? Icons.route
                        : Icons.location_off,
                    color: isServiceable
                        ? Colors.deepPurple
                        : Colors.redAccent,
                  ),
                  const SizedBox(
                      width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          "Delivery Distance",
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: isServiceable
                                ? Colors
                                    .black
                                : Colors
                                    .redAccent,
                          ),
                        ),
                        const SizedBox(
                            height: 3),
                        Text(
                          "${distanceKm.toStringAsFixed(1)} km",
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isServiceable)
                    const Text(
                      "Not serviceable",
                      style:
                          TextStyle(
                        color:
                            Colors.redAccent,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

          // ------------------------------------------------------
          // PAYMENT METHOD
          // ------------------------------------------------------

          const Text(
            "Payment Method",
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
              height: 10),

          paymentTile(
            "Cash on Delivery",
            "COD",
            Icons.money,
            enabled:
                BillingService
                    .codEnabled,
            unavailableMessage:
                "Cash on Delivery is not currently available",
          ),

          paymentTile(
            "UPI",
            "UPI",
            Icons.account_balance,
          ),

          paymentTile(
            "Credit / Debit Card",
            "CARD",
            Icons.credit_card,
          ),

          paymentTile(
            "Wallet",
            "WALLET",
            Icons.account_balance_wallet,
            enabled: false,
            unavailableMessage:
                "Wallet is coming soon",
          ),

          const SizedBox(
              height: 20),

          // ------------------------------------------------------
          // BILL
          // ------------------------------------------------------
          if (bill != null)
            Container(
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: Column(
                children: [
                  summaryRow(
                    "Item Total",
                    bill.itemsTotal,
                  ),
                  summaryRow(
                    "Delivery Fee",
                    bill.deliveryFee,
                  ),
                  if (bill
                          .longDistanceCharge >
                      0)
                    summaryRow(
                      "Long Distance Charge",
                      bill.longDistanceCharge,
                    ),
                  summaryRow(
                    "Platform Fee",
                    bill.platformFee,
                  ),
                  summaryRow(
                    "Discount",
                    -bill.couponDiscount,
                  ),
                  const Divider(),
                  summaryRow(
                    "Grand Total",
                    bill.grandTotal,
                    isBold: true,
                  ),
                ],
              ),
            ),

          if (bill == null &&
              hasValidAddress)
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    Colors.red.shade50,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Text(
                "Unable to calculate the delivery charge. Please try again.",
                style: TextStyle(
                  color:
                      Colors.redAccent,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(
              height: 30),

          // ------------------------------------------------------
          // PLACE ORDER / PAY BUTTON
          // ------------------------------------------------------

          SizedBox(
            width:
                double.infinity,
            height: 55,
            child:
                ElevatedButton(
              onPressed:
                  isLoading ||
                          !hasValidAddress ||
                          bill == null ||
                          distanceKm ==
                              null ||
                          !isServiceable
                      ? null
                      : () async {
                          await _handlePlaceOrder(
                            uid: uid,
                            subtotal:
                                subtotal,
                            cartDocs:
                                cartDocs,
                            restaurantId:
                                restaurantId,
                          );
                        },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepPurple,
                foregroundColor:
                    Colors.white,
                disabledBackgroundColor:
                    Colors.grey.shade400,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      color:
                          Colors.white,
                    )
                  : Text(
                      selectedPayment ==
                              "COD"
                          ? "Place Order"
                          : "Pay & Place Order",
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MAIN PLACE ORDER HANDLER
  // ------------------------------------------------------------

  Future<void> _handlePlaceOrder({
    required String uid,
    required double subtotal,
    required List<
            QueryDocumentSnapshot>
        cartDocs,
    required String restaurantId,
  }) async {
    if (selectedPayment ==
            "COD" &&
        !BillingService
            .codEnabled) {
      await _showCodUnavailablePopup();
      return;
    }

    if (selectedPayment ==
        "WALLET") {
      return;
    }

    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    _showLoadingOverlay();

    try {
      // --------------------------------------------------------
      // 1. Get latest selected address
      // --------------------------------------------------------

      final latestAddress =
          await _getSelectedAddress(
        uid,
      );

      if (!_isValidAddress(
        latestAddress,
      )) {
        _hideLoadingOverlay();

        await _showAddressRequiredPopup();

        return;
      }

      // --------------------------------------------------------
      // 2. Recalculate latest distance
      // --------------------------------------------------------

      final latestDistance =
          await _getDistanceKm(
        restaurantId:
            restaurantId,
        address:
            latestAddress!,
      );

      if (latestDistance == null) {
        throw Exception(
          "Unable to calculate delivery distance.",
        );
      }

      if (!BillingService
          .isWithinServiceableRadius(
        latestDistance,
      )) {
        _hideLoadingOverlay();

        await _showServiceabilityPopup(
          latestDistance,
        );

        return;
      }

      // --------------------------------------------------------
      // 3. Calculate local bill for OrderModel/display
      // --------------------------------------------------------

      final finalBill =
          BillingService.calculateBill(
        itemsTotal:
            subtotal,
        couponDiscount:
            widget.couponApplied
                ? widget.couponDiscount
                : 0,
        couponCode:
            widget.couponCode,
        distanceKm:
            latestDistance,
      );

      // --------------------------------------------------------
      // 4. Build order ID and order number
      // --------------------------------------------------------

      final orderId =
          FirebaseFirestore
              .instance
              .collection("orders")
              .doc()
              .id;

      final orderNumber =
          "JMB${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

      // --------------------------------------------------------
      // 5. Prepare cart items
      // --------------------------------------------------------

      final List<
              Map<String, dynamic>>
          items = [];

      String finalRestaurantId =
          "";

      String finalRestaurantName =
          "";

      for (final doc
          in cartDocs) {
        final data =
            doc.data()
                as Map<String,
                    dynamic>;

        items.add(
          Map<String, dynamic>.from(
            data,
          ),
        );

        finalRestaurantId =
            (data["restaurantId"] ??
                    "")
                .toString();

        finalRestaurantName =
            (data["restaurantName"] ??
                    "")
                .toString();
      }

      if (finalRestaurantId
          .isEmpty) {
        throw Exception(
          "Restaurant information is missing.",
        );
      }

      // --------------------------------------------------------
      // 6. Get customer
      // --------------------------------------------------------

      final userDoc =
          await FirebaseFirestore
              .instance
              .collection("users")
              .doc(uid)
              .get();

      final userData =
          userDoc.data() ?? {};

      // --------------------------------------------------------
      // 7. Get restaurant
      // --------------------------------------------------------

      final restaurantDoc =
          await FirebaseFirestore
              .instance
              .collection(
                "restaurant_registrations",
              )
              .doc(
                finalRestaurantId,
              )
              .get();

      if (!restaurantDoc.exists) {
        throw Exception(
          "Restaurant not found.",
        );
      }

      final restaurantData =
          restaurantDoc.data() ??
              {};

      final restaurantAddress =
          restaurantData[
                  "address"] ??
              "";

      final restaurantLatitude =
          (restaurantData[
                      "latitude"] ??
                  0)
              .toDouble();

      final restaurantLongitude =
          (restaurantData[
                      "longitude"] ??
                  0)
              .toDouble();

      final customerLatitude =
          (latestAddress[
                      "latitude"] ??
                  0)
              .toDouble();

      final customerLongitude =
          (latestAddress[
                      "longitude"] ??
                  0)
              .toDouble();

      // --------------------------------------------------------
      // 8. Create OrderModel
      // --------------------------------------------------------

      final order =
          OrderModel(
        orderId:
            orderId,
        orderNumber:
            orderNumber,

        userId:
            uid,

        customerName:
            userData[
                    "fullName"] ??
                "",

        customerPhone:
            userData[
                    "phone"] ??
                "",

        deliveryPartnerId:
            "",

        deliveryPartnerName:
            "",

        deliveryPartnerPhone:
            "",

        vehicleNumber:
            "",

        restaurantId:
            finalRestaurantId,

        restaurantName:
            finalRestaurantName,

        restaurantAddress:
            restaurantAddress,

        restaurantLatitude:
            restaurantLatitude,

        restaurantLongitude:
            restaurantLongitude,

        items:
            items,

        deliveryAddress:
            latestAddress,

        customerLatitude:
            customerLatitude,

        customerLongitude:
            customerLongitude,

        paymentMethod:
            selectedPayment,

        paymentStatus:
            selectedPayment ==
                    "COD"
                ? "Pending"
                : "Pending",

        orderStatus:
            "Pending",

        subtotal:
            subtotal,

        deliveryFee:
            finalBill.deliveryFee,

        longDistanceCharge:
            finalBill
                .longDistanceCharge,

        platformFee:
            finalBill
                .platformFee,

        discount:
            finalBill
                .couponDiscount,

        totalAmount:
            finalBill.grandTotal,

        createdAt:
            DateTime.now(),
      );

      // --------------------------------------------------------
      // COD FLOW
      // --------------------------------------------------------

      if (selectedPayment ==
          "COD") {
        await _orderService
            .placeOrder(
          order,
          couponCode:
              widget.couponApplied
                  ? widget
                      .couponCode
                  : null,
        );

        _hideLoadingOverlay();

        if (!mounted) return;

        try {
          await _cartService
              .clearCart();
        } catch (_) {
          // Order is already placed.
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OrderDetailsScreen(
              order: order,
            ),
          ),
        );

        return;
      }

      // --------------------------------------------------------
      // ONLINE PAYMENT FLOW
      // --------------------------------------------------------
      // First create a server-side payment intent.
      final paymentIntent =
          await _orderService
              .createPaymentIntent(
        orderId:
            orderId,
        orderNumber:
            orderNumber,
        restaurantId:
            finalRestaurantId,
        paymentMethod:
            selectedPayment,
        items:
            items,
        deliveryAddress:
            latestAddress,
        customerLatitude:
            customerLatitude,
        customerLongitude:
            customerLongitude,
        customerName:
            userData["fullName"] ??
                "",
        customerPhone:
            userData["phone"] ??
                "",
        couponCode:
            widget.couponApplied
                ? widget.couponCode
                : null,
        customerNote:
            order.customerNote,
      );

      final paymentId =
          (paymentIntent[
                      "paymentId"] ??
                  "")
              .toString();

      if (paymentId.isEmpty) {
        throw Exception(
          "Unable to create payment request.",
        );
      }

      final serverAmount =
    (paymentIntent["amountInPaise"] as num?)?.toInt() ?? 0;

      if (serverAmount <= 0) {
        throw Exception(
          "Invalid payment amount received from server.",
        );
      }

      // --------------------------------------------------------
      // Create Razorpay order from server-side payment intent.
      // --------------------------------------------------------

      final razorpayOrder =
          await _orderService
              .createRazorpayOrder(
        paymentId:
            paymentId,
      );

      final razorpayOrderId =
          (razorpayOrder[
                      "orderId"] ??
                  "")
              .toString();

      final razorpayKeyId =
          (razorpayOrder[
                      "keyId"] ??
                  "")
              .toString();

      final razorpayAmount =
    (razorpayOrder["amount"] as num?)?.toInt() ?? 0;

      if (razorpayOrderId
              .isEmpty ||
          razorpayKeyId
              .isEmpty ||
          razorpayAmount <= 0) {
        throw Exception(
          "Unable to create Razorpay order.",
        );
      }

      if (razorpayAmount !=
          serverAmount) {
        throw Exception(
          "Payment amount mismatch. Please try again.",
        );
      }

      // --------------------------------------------------------
      // Save pending payment state.
      // --------------------------------------------------------

      _pendingPaymentId =
          paymentId;

      _pendingRazorpayOrderId =
          razorpayOrderId;

      _pendingOrder =
          order;

      // Remove our loading overlay before Razorpay opens.
      _hideLoadingOverlay();

      if (!mounted) return;

      // --------------------------------------------------------
      // Open Razorpay Checkout
      // --------------------------------------------------------

      final currentUser =
          FirebaseAuth
              .instance
              .currentUser;

      final email =
          currentUser?.email;

      final phone =
          userData["phone"]
                  ?.toString() ??
              "";

      final name =
          userData["fullName"]
                  ?.toString() ??
              "Jamboo Customer";

      final Map<String, dynamic>
          options = {
        "key":
            razorpayKeyId,

        "amount":
            razorpayAmount,

        "currency":
            "INR",

        "order_id":
            razorpayOrderId,

        "name":
            "Jamboo",

        "description":
            "Food order payment",

        "prefill": {
          "name":
              name,
          "contact":
              phone,
          if (email != null &&
              email
                  .trim()
                  .isNotEmpty)
            "email":
                email.trim(),
        },

        "theme": {
          "color":
              "#7E57C2",
        },
      };

      // --------------------------------------------------------
      // Important:
      //
      // We intentionally do not trust the client-side success
      // callback as proof of payment.
      //
      // _handlePaymentSuccess() sends the Razorpay payment ID,
      // order ID and signature to Firebase for verification.
      // --------------------------------------------------------

      _razorpay.open(
        options,
      );
    } catch (e) {
      _hideLoadingOverlay();

      _clearPendingPayment();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _cleanErrorMessage(e),
          ),
          duration:
              const Duration(seconds: 4),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // PAYMENT TILE
  // ------------------------------------------------------------

  Widget paymentTile(
    String title,
    String value,
    IconData icon, {
    bool enabled = true,
    String? unavailableMessage,
  }) {
    final bool isSelected =
        selectedPayment ==
            value;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration:
          BoxDecoration(
        color: enabled
            ? Colors.white
            : Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              isSelected && enabled
                  ? Colors.deepPurple
                  : Colors.transparent,
          width: 1.5,
        ),
      ),
      child:
          IgnorePointer(
        ignoring:
            !enabled,
        child:
            RadioListTile<
                String>(
          value:
              value,
          groupValue:
              selectedPayment,
          onChanged:
              enabled
                  ? (newValue) {
                      if (newValue ==
                          null) {
                        return;
                      }

                      setState(() {
                        selectedPayment =
                            newValue;
                      });
                    }
                  : null,
          title:
              Text(
            title,
            style:
                TextStyle(
              color: enabled
                  ? Colors.black
                  : Colors
                      .grey
                      .shade600,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          subtitle:
              unavailableMessage !=
                          null &&
                      !enabled
                  ? Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        top: 4,
                      ),
                      child:
                          Text(
                        unavailableMessage,
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                          fontSize:
                              12,
                        ),
                      ),
                    )
                  : null,
          secondary:
              Icon(
            icon,
            color: enabled
                ? Colors
                    .deepPurple
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY ROW
  // ------------------------------------------------------------

  Widget summaryRow(
    String title,
    double amount, {
    bool isBold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  TextStyle(
                fontWeight:
                    isBold
                        ? FontWeight
                            .bold
                        : FontWeight
                            .normal,
                fontSize:
                    isBold
                        ? 16
                        : 14,
              ),
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style:
                TextStyle(
              fontWeight:
                  isBold
                      ? FontWeight
                          .bold
                      : FontWeight
                          .normal,
              fontSize:
                  isBold
                      ? 16
                      : 14,
            ),
          ),
        ],
      ),
    );
  }
}
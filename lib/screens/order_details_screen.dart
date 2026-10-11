import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';

import '../order_details/order_details_status_helper.dart';
import '../order_details/order_details_action_handler.dart';

import '../order_details/widgets/01_order_header.dart';
import '../order_details/widgets/02_delivery_timeline.dart';
import '../order_details/widgets/03_restaurant_info_card.dart';
import '../order_details/widgets/04_ordered_items_card.dart';
import '../order_details/widgets/05_delivery_address_card.dart';
import '../order_details/widgets/06_bill_summary_card.dart';
import '../order_details/widgets/07_order_action_buttons.dart';
import '../order_details/widgets/08_feedback_thank_you_card.dart';
import '../order_details/widgets/09_order_contact_actions.dart';
import 'live_tracking_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsScreen> createState() =>
      _OrderDetailsScreenState();
}

class _OrderDetailsScreenState
    extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();

  final CartService _cartService = CartService();

  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: const IconThemeData(
          color: Color(0xFF171717),
        ),
        title: const Text(
          "Order Details",
          style: TextStyle(
            color: Color(0xFF171717),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: _orderService.watchOrder(
          widget.order.orderId,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7E57C2),
              ),
            );
          }

          final data =
              snapshot.data!.data()
                  as Map<String, dynamic>;

          final order = OrderModel.fromMap(data);

          final statusColor =
              OrderDetailsStatusHelper.statusColor(
            order.orderStatus,
          );

          final statusTitle =
              OrderDetailsStatusHelper.statusTitle(
            order.orderStatus,
          );

          final statusMessage =
              OrderDetailsStatusHelper.statusMessage(
            order.orderStatus,
          );

          final statusIcon =
              OrderDetailsStatusHelper.statusIcon(
            order.orderStatus,
          );

          final canCancelOrder =
              OrderDetailsStatusHelper.canCancelOrder(
            createdAt: order.createdAt,
            orderStatus: order.orderStatus,
          );

          final normalizedOrderStatus =
              order.orderStatus
                  .toLowerCase()
                  .replaceAll(" ", "")
                  .replaceAll("_", "");

          // Track Order button is available ONLY
          // when the rider has the order and it is
          // actually Out For Delivery.
          final canTrackOrder =
              normalizedOrderStatus ==
                  "outfordelivery";

          // Show the information message before
          // Out For Delivery, so customer knows that
          // live tracking is coming.
          final showTrackingInfo =
              normalizedOrderStatus !=
                      "delivered" &&
                  normalizedOrderStatus !=
                      "cancelled" &&
                  !canTrackOrder;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              24,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                OrderHeader(
                  statusColor: statusColor,
                  statusIcon: statusIcon,
                  statusTitle: statusTitle,
                  statusMessage: statusMessage,
                  orderData: data,
                ),

                const SizedBox(height: 18),

                DeliveryTimeline(
                  statusColor: statusColor,
                  orderStatus: order.orderStatus,
                  journeyStep: (
                    emoji,
                    title,
                    completed,
                  ) {
                    return OrderDetailsStatusHelper
                        .journeyStep(
                      emoji: emoji,
                      title: title,
                      completed: completed,
                      statusColor: statusColor,
                    );
                  },
                ),

                // ---------------------------------------------------------
                // LIVE TRACKING
                // ---------------------------------------------------------
                if (canTrackOrder) ...[
                  const SizedBox(height: 14),

                  _LiveTrackingButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LiveTrackingScreen(
                            orderId:
                                order.orderId,
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // ---------------------------------------------------------
                // TRACKING INFORMATION BEFORE OUT FOR DELIVERY
                // ---------------------------------------------------------
                if (showTrackingInfo) ...[
                  const SizedBox(height: 14),

                  const _LiveTrackingInfoCard(),
                ],

                const SizedBox(height: 16),

                // ---------------------------------------------------------
                // ORDER NUMBER + CUSTOMER DELIVERY OTP
                // ---------------------------------------------------------
                _OrderNumberAndOtpCard(
                  orderNumber: order.orderNumber,
                ),

                const SizedBox(height: 12),

                RestaurantInfoCard(
                  order: order,
                ),

                const SizedBox(height: 12),

                OrderedItemsCard(
                  order: order,
                ),

                const SizedBox(height: 12),

                DeliveryAddressCard(
                  order: order,
                ),

                const SizedBox(height: 12),

                BillSummaryCard(
                  order: order,
                ),

                const SizedBox(height: 12),

                OrderContactActions(
                  showRestaurantButton:
                      normalizedOrderStatus !=
                              "pickedup" &&
                          normalizedOrderStatus !=
                              "outfordelivery" &&
                          normalizedOrderStatus !=
                              "delivered",

                  showRiderButton:
                      normalizedOrderStatus ==
                              "pickedup" ||
                          normalizedOrderStatus ==
                              "outfordelivery",

                  riderName:
                      order.deliveryPartnerName,

                  riderPhone:
                      order.deliveryPartnerPhone,

                  vehicleNumber:
                      order.vehicleNumber,

                  onCallRestaurant: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Restaurant calling will be added soon",
                        ),
                      ),
                    );
                  },

                  onCallRider: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Rider calling will be available after rider assignment",
                        ),
                      ),
                    );
                  },

                  onLeaveNote: () async {
                    final controller =
                        TextEditingController();

                    final note =
                        await showDialog<String>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text(
                            "Leave a Note",
                          ),
                          content: TextField(
                            controller:
                                controller,
                            maxLines: 3,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  "Example: Please call before delivery",
                              border:
                                  OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                              },
                              child:
                                  const Text(
                                "Cancel",
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  controller
                                      .text
                                      .trim(),
                                );
                              },
                              child:
                                  const Text(
                                "Save",
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (note == null ||
                        note.isEmpty) {
                      return;
                    }

                    await _orderService
                        .updateCustomerNote(
                      orderId:
                          order.orderId,
                      note: note,
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Note saved successfully",
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                OrderActionButtons(
                  canCancelOrder:
                      canCancelOrder,

                  showRatingButton:
                      normalizedOrderStatus ==
                              "delivered" &&
                          !order.isRated,

                  showReorderButton:
                      normalizedOrderStatus ==
                              "delivered" ||
                          normalizedOrderStatus ==
                              "cancelled",

                  isReordering:
                      _isReordering,

                  onCancel: () async {
                    await OrderDetailsActionHandler
                        .cancelOrder(
                      context: context,
                      order: order,
                      orderService:
                          _orderService,
                    );
                  },

                  onRate: () async {
                    await OrderDetailsActionHandler
                        .openRatingScreen(
                      context: context,
                      order: order,
                    );
                  },

                  onReorder: () async {
                    await OrderDetailsActionHandler
                        .reorderOrder(
                      context: context,
                      order: order,
                      cartService:
                          _cartService,
                      isReordering:
                          _isReordering,
                      startLoading: () {
                        if (!mounted) return;

                        setState(() {
                          _isReordering = true;
                        });
                      },
                      stopLoading: () {
                        if (!mounted) return;

                        setState(() {
                          _isReordering = false;
                        });
                      },
                    );
                  },
                ),

                if (normalizedOrderStatus ==
                        "delivered" &&
                    order.isRated) ...[
                  const SizedBox(height: 12),

                  FeedbackThankYouCard(
                    rating:
                        order.rating.toInt(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// LIVE TRACKING BUTTON
// ===========================================================================

class _LiveTrackingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LiveTrackingButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7E57C2),
            Color(0xFF6A45B8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E57C2)
                .withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius:
              BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.18),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 13),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Track Your Order",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Follow your delivery partner live",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// LIVE TRACKING INFORMATION CARD
// ===========================================================================

class _LiveTrackingInfoCard
    extends StatelessWidget {
  const _LiveTrackingInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5D9FF),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_searching_rounded,
              color: Color(0xFF7E57C2),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Live Tracking",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Live tracking will be available once your rider picks up your order and it is Out for Delivery.",
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ORDER NUMBER + DELIVERY OTP CARD
// ===========================================================================

class _OrderNumberAndOtpCard
    extends StatelessWidget {
  final String orderNumber;

  const _OrderNumberAndOtpCard({
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    final digits = orderNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final String deliveryOtp =
        digits.length >= 4
            ? digits.substring(0, 4)
            : "----";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5D9FF),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF171717),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: Color(0xFF7E57C2),
              ),

              const SizedBox(width: 10),

              const Text(
                "Order No.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const Spacer(),

              Flexible(
                child: Text(
                  orderNumber,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text(
                  "🏠",
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Delivery OTP",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        "Share this OTP with the rider",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  deliveryOtp,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Color(0xFF7E57C2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
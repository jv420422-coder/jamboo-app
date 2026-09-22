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

          final canTrackOrder =
              normalizedOrderStatus == "pickedup" ||
              normalizedOrderStatus == "outfordelivery";

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

                const SizedBox(height: 16),

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

                if (canTrackOrder) ...[
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.location_on_rounded,
                        size: 19,
                      ),
                      label: const Text(
                        "Track Order",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFEAF8EE),
                        foregroundColor:
                            Colors.green.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(13),
                          side: BorderSide(
                            color: Colors.green.shade100,
                          ),
                        ),
                      ),
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
                  ),
                ],

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
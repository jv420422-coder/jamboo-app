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
  final OrderService _orderService =
      OrderService();

  final CartService _cartService =
      CartService();

  bool _isReordering = false;

  Color get statusColor =>
      OrderDetailsStatusHelper.statusColor(
        widget.order.orderStatus,
      );

  String get statusTitle =>
      OrderDetailsStatusHelper.statusTitle(
        widget.order.orderStatus,
      );

  String get statusMessage =>
      OrderDetailsStatusHelper.statusMessage(
        widget.order.orderStatus,
      );

  IconData get statusIcon =>
      OrderDetailsStatusHelper.statusIcon(
        widget.order.orderStatus,
      );

  bool get canCancelOrder =>
      OrderDetailsStatusHelper.canCancelOrder(
        createdAt: widget.order.createdAt,
        orderStatus: widget.order.orderStatus,
      );

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
          "Order Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            OrderHeader(
              statusColor: statusColor,
              statusIcon: statusIcon,
              statusTitle: statusTitle,
              statusMessage: statusMessage,
            ),

            const SizedBox(height: 28),

            DeliveryTimeline(
              statusColor: statusColor,
              orderStatus:
                  widget.order.orderStatus,

              journeyStep:
                  (
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

            const SizedBox(height: 24),

            RestaurantInfoCard(
              order: widget.order,
            ),

            const SizedBox(height: 24),

            OrderedItemsCard(
              order: widget.order,
            ),

            const SizedBox(height: 24),

            DeliveryAddressCard(
              order: widget.order,
            ),

            const SizedBox(height: 24),

            BillSummaryCard(
              order: widget.order,
            ),

            const SizedBox(height: 30),
            OrderActionButtons(
              canCancelOrder: canCancelOrder,

              showRatingButton:
                  widget.order.orderStatus ==
                          "Delivered" &&
                      !widget.order.isRated,

              showReorderButton:
                  widget.order.orderStatus ==
                          "Delivered" ||
                      widget.order.orderStatus ==
                          "Cancelled",

              isReordering: _isReordering,

              onCancel: () async {
                await OrderDetailsActionHandler.cancelOrder(
                  context: context,
                  order: widget.order,
                  orderService: _orderService,
                );
              },

              onRate: () async {
                await OrderDetailsActionHandler
                    .openRatingScreen(
                  context: context,
                  order: widget.order,
                );
              },

              onReorder: () async {
                await OrderDetailsActionHandler
                    .reorderOrder(
                  context: context,
                  order: widget.order,
                  cartService: _cartService,
                  isReordering: _isReordering,

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
          ],
        ),
      ),
    );
  }
}
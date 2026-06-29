import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';

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

    bool isCancelling = false;
  Color get statusColor {

    switch (widget.order.orderStatus) {

      case "Pending":
        return Colors.orange;

      case "Accepted":
        return Colors.blue;

      case "Preparing":
        return Colors.deepPurple;

      case "Ready":
        return Colors.indigo;

      case "PickedUp":
        return Colors.teal;

      case "OutForDelivery":
        return Colors.green;

      case "Delivered":
        return Colors.green;

      case "Cancelled":
        return Colors.red;

      default:
        return Colors.deepPurple;
    }
  }

  String get statusTitle {

    switch (widget.order.orderStatus) {

      case "Pending":
        return "Order Received";

      case "Accepted":
        return "Restaurant Accepted";

      case "Preparing":
        return "Preparing Food";

      case "Ready":
        return "Ready For Pickup";

      case "PickedUp":
        return "Picked Up";

      case "OutForDelivery":
        return "On The Way";

      case "Delivered":
        return "Delivered";

      case "Cancelled":
        return "Order Cancelled";

      default:
        return "Processing";
    }
  }

  String get statusMessage {

    switch (widget.order.orderStatus) {

      case "Pending":
        return "Your restaurant has received the order.";

      case "Accepted":
        return "Restaurant accepted your order.";

      case "Preparing":
        return "Our chefs are preparing your delicious meal.";

      case "Ready":
        return "Your order is packed and ready.";

      case "PickedUp":
        return "Delivery partner picked your order.";

      case "OutForDelivery":
        return "Your food is almost there.";

      case "Delivered":
        return "Enjoy your delicious meal.";

      case "Cancelled":
        return "This order has been cancelled.";

      default:
        return "";
    }
  }

  IconData get statusIcon {

    switch (widget.order.orderStatus) {

      case "Pending":
        return Icons.receipt_long;

      case "Accepted":
        return Icons.check_circle;

      case "Preparing":
        return Icons.restaurant;

      case "Ready":
        return Icons.inventory;

      case "PickedUp":
        return Icons.delivery_dining;

      case "OutForDelivery":
        return Icons.local_shipping;

      case "Delivered":
        return Icons.celebration;

      case "Cancelled":
        return Icons.cancel;

      default:
        return Icons.restaurant;
    }
  }
  bool get canCancelOrder {

  final difference = DateTime.now().difference(
    widget.order.createdAt,
  );

  return difference.inMinutes < 2 &&
      widget.order.orderStatus != "Cancelled";
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

            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.all(22),

              decoration: BoxDecoration(

                color: statusColor,

                borderRadius:
                    BorderRadius.circular(22),

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

                  const SizedBox(height: 16),

                  Row(

                    children: [

                      Icon(

                        statusIcon,

                        color: Colors.white,

                        size: 34,

                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: Text(

                          statusTitle,

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

                  const SizedBox(height: 12),

                  Text(

                    statusMessage,

                    style: const TextStyle(

                      color: Colors.white70,

                      height: 1.5,

                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(

                    padding:
                        const EdgeInsets.symmetric(

                      horizontal: 16,

                      vertical: 12,

                    ),

                    decoration: BoxDecoration(

                      color: Colors.white24,

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: const Row(

                      children: [

                        Icon(

                          Icons.timer,

                          color: Colors.white,

                        ),

                        SizedBox(width: 10),

                        Text(

                          "Estimated Delivery • 22 mins",

                          style: TextStyle(

                            color: Colors.white,

                            fontWeight:
                                FontWeight.bold,

                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            // Delivery Journey

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Delivery Journey",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [

                      journeyStep(
                        "🏪",
                        "Placed",
                        true,
                      ),

                      Expanded(
                        child: Divider(
                          color: statusColor,
                          thickness: 2,
                        ),
                      ),

                      journeyStep(
                        "👨‍🍳",
                        "Preparing",
                        widget.order.orderStatus !=
                            "Pending",
                      ),

                      Expanded(
                        child: Divider(
                          color: statusColor,
                          thickness: 2,
                        ),
                      ),

                      journeyStep(
                        "🛵",
                        "On Way",
                        widget.order.orderStatus ==
                                "PickedUp" ||
                            widget.order.orderStatus ==
                                "OutForDelivery" ||
                            widget.order.orderStatus ==
                                "Delivered",
                      ),

                      Expanded(
                        child: Divider(
                          color: statusColor,
                          thickness: 2,
                        ),
                      ),

                      journeyStep(
                        "🏠",
                        "Delivered",
                        widget.order.orderStatus ==
                            "Delivered",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Restaurant Card

            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    widget.order.restaurantName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [

                      const Icon(
                        Icons.receipt_long,
                        size: 18,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        "Order #${widget.order.orderNumber}",
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [

                      const Icon(
                        Icons.schedule,
                        size: 18,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        DateFormat(
                          "dd MMM yyyy • hh:mm a",
                        ).format(
                          widget.order.createdAt,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ordered Items

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Ordered Items",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ...widget.order.items.map((item) {

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [

                          Expanded(
                            child: Text(
                              "${item["itemName"]} × ${item["quantity"]}",
                            ),
                          ),

                          Text(
                            "₹${item["price"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        ],
                      ),
                    );

                  }).toList(),

                ],
              ),
            ),

            const SizedBox(height: 24),

            // Delivery Address

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Delivery Address",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.order.deliveryAddress["fullName"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(widget.order.deliveryAddress["phone"] ?? ""),

                  const SizedBox(height: 6),

                  Text(
                    "${widget.order.deliveryAddress["address"]}\n${widget.order.deliveryAddress["city"]}",
                  ),

                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment & Bill

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [

                  billRow(
                    "Items Total",
                    "₹${widget.order.subtotal.toStringAsFixed(0)}",
                  ),

                  billRow(
                    "Delivery Fee",
                    "₹${widget.order.deliveryFee.toStringAsFixed(0)}",
                  ),

                  billRow(
                    "Discount",
                    "-₹${widget.order.discount.toStringAsFixed(0)}",
                  ),

                  const Divider(),

                  billRow(
                    "Grand Total",
                    "₹${widget.order.totalAmount.toStringAsFixed(0)}",
                    bold: true,
                  ),

                ],
              ),
            ),

            const SizedBox(height: 30),
            if (canCancelOrder) ...[

  SizedBox(
    width: double.infinity,
    height: 55,

    child: ElevatedButton.icon(

      onPressed: () {

  showDialog(
    context: context,

    builder: (dialogContext) {

      return AlertDialog(

        title: const Text(
          "Cancel Order",
        ),

        content: const Text(
          "Are you sure you want to cancel this order?",
        ),

        actions: [

          TextButton(

            onPressed: () {
              Navigator.pop(context);
            },

            child: const Text("No"),
          ),

          ElevatedButton(

            onPressed: () async {

              Navigator.pop(context);

await _orderService.cancelOrder(
  orderId: widget.order.orderId,
  cancelledBy: "customer",
);

if (!mounted) return;

Navigator.pop(context, true);

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Order cancelled successfully"),
  ),
);

            },

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),

            child: const Text(
              "Yes, Cancel",
            ),
          ),
        ],
      );
    },
  );
},

      icon: const Icon(Icons.cancel),

      label: const Text(
        "Cancel Order",
      ),

      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    ),
  ),

  const SizedBox(height: 20),

],

          ],
        ),
      ),
    );
  }

  Widget billRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),

        ],
      ),
    );
  }

  Widget journeyStep(
    String emoji,
    String title,
    bool completed,
  ) {
    return Column(
      children: [

        CircleAvatar(
          radius: 22,
          backgroundColor:
              completed
                  ? statusColor
                  : Colors.grey.shade300,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),

      ],
    );
  }
}
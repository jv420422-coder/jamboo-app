import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../services/order_service.dart';
import '../models/order_model.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() =>
      _MyOrdersScreenState();
}

class _MyOrdersScreenState
    extends State<MyOrdersScreen> {
  final OrderService _orderService =
      OrderService();

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "📦 My Orders",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _orderService.getUserOrders(uid),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text(
                      "📦",
                      style: TextStyle(
                        fontSize: 70,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "No Orders Yet",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Looks like you haven't placed any order yet.",
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.deepPurple,
                        foregroundColor:
                            Colors.white,
                      ),
                      child:
                          const Text(
                        "Browse Food",
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs =
              snapshot.data!.docs;

          List<OrderModel> activeOrders = [];
          List<OrderModel> pastOrders = [];

          for (final doc in docs) {
            final order =
                OrderModel.fromMap(
              doc.data()
                  as Map<String, dynamic>,
            );

            final normalizedStatus =
                order.orderStatus
                    .toLowerCase()
                    .replaceAll(
                      " ",
                      "",
                    );

            if (normalizedStatus ==
                    "delivered" ||
                normalizedStatus ==
                    "cancelled") {
              pastOrders.add(order);
            } else {
              activeOrders.add(order);
            }
          }

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                if (activeOrders.isNotEmpty) ...[
                  const Text(
                    "ACTIVE ORDERS",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...activeOrders.map(
                    (order) =>
                        orderCard(order),
                  ),

                  const SizedBox(height: 24),
                ],

                if (pastOrders.isNotEmpty) ...[
                  const Text(
                    "PAST ORDERS",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...pastOrders.map(
                    (order) =>
                        orderCard(order),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget orderCard(OrderModel order) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(18),

      onTap: () async {
        final result =
            await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OrderDetailsScreen(
              order: order,
            ),
          ),
        );

        if (!context.mounted) return;

        if (result == "cancelled") {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Order cancelled successfully",
              ),
            ),
          );
        }

        if (result == "rated") {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Thank you for your valuable feedback ❤️",
              ),
            ),
          );
        }
      },

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 16,
        ),

        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              order.restaurantName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Order #${order.orderNumber}",
            ),

            const SizedBox(height: 6),

            Text(
              "${order.items.length} Items • ₹${order.totalAmount.toStringAsFixed(0)}",
            ),

            const SizedBox(height: 6),

            Text(
              DateFormat(
                "dd MMM yyyy • hh:mm a",
              ).format(order.createdAt),
            ),

            const SizedBox(height: 14),

            Align(
              alignment:
                  Alignment.centerLeft,

              child: statusChip(
                order.orderStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusChip(String status) {
    final normalizedStatus =
        status
            .toLowerCase()
            .replaceAll(
              " ",
              "",
            )
            .replaceAll(
              "_",
              "",
            );

    IconData icon;
    Color color;
    String displayStatus;

    switch (normalizedStatus) {
      case "pending":
        icon = Icons.schedule_rounded;
        color = Colors.orange;
        displayStatus = "Pending";
        break;

      case "accepted":
        icon = Icons.thumb_up_rounded;
        color = Colors.blue;
        displayStatus = "Accepted";
        break;

      case "preparing":
        icon = Icons.restaurant_rounded;
        color = Colors.deepPurple;
        displayStatus = "Preparing";
        break;

      case "ready":
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        displayStatus = "Ready";
        break;

      case "pickedup":
        icon = Icons.delivery_dining_rounded;
        color = Colors.teal;
        displayStatus = "Picked Up";
        break;

      case "outfordelivery":
        icon = Icons.local_shipping_rounded;
        color = Colors.blue;
        displayStatus = "Out For Delivery";
        break;

      case "delivered":
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        displayStatus = "Delivered";
        break;

      case "cancelled":
        icon = Icons.cancel_rounded;
        color = Colors.red;
        displayStatus = "Cancelled";
        break;

      default:
        icon = Icons.info_rounded;
        color = Colors.grey;
        displayStatus =
            _formatStatus(status);
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),

          const SizedBox(width: 7),

          Text(
            displayStatus,
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    final words =
        status
            .replaceAll(
              "_",
              " ",
            )
            .replaceAll(
              "-",
              " ",
            )
            .trim()
            .split(RegExp(r'\s+'));

    return words
        .where(
          (word) => word.isNotEmpty,
        )
        .map(
          (word) =>
              word[0].toUpperCase() +
              word.substring(1).toLowerCase(),
        )
        .join(" ");
  }
}
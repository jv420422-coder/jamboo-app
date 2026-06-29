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
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
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
                      textAlign: TextAlign.center,
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
                      child: const Text(
                        "Browse Food",
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          List<OrderModel> activeOrders = [];
          List<OrderModel> pastOrders = [];

          for (final doc in docs) {

            final order =
                OrderModel.fromMap(
              doc.data()
                  as Map<String, dynamic>,
            );

            if (order.orderStatus ==
                    "Delivered" ||
                order.orderStatus ==
                    "Cancelled") {

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

              children: [if (activeOrders.isNotEmpty) ...[
                  const Text(
                    "ACTIVE ORDERS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...activeOrders.map(
                    (order) => orderCard(order),
                  ),

                  const SizedBox(height: 24),
                ],

                if (pastOrders.isNotEmpty) ...[
                  const Text(
                    "PAST ORDERS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...pastOrders.map(
                    (order) => orderCard(order),
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
  borderRadius: BorderRadius.circular(18),

  onTap: () async {

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => OrderDetailsScreen(
        order: order,
      ),
    ),
  );

  if (!context.mounted) return;

  if (result == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Order cancelled successfully",
        ),
      ),
    );
  }
},

  child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              fontWeight: FontWeight.bold,
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
            alignment: Alignment.centerLeft,
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

    IconData icon;
    Color color;

    switch (status) {

      case "Pending":
        icon = Icons.schedule;
        color = Colors.orange;
        break;

      case "Accepted":
        icon = Icons.thumb_up;
        color = Colors.blue;
        break;

      case "Preparing":
        icon = Icons.restaurant;
        color = Colors.deepPurple;
        break;

      case "Ready":
        icon = Icons.inventory;
        color = Colors.indigo;
        break;

      case "PickedUp":
        icon = Icons.delivery_dining;
        color = Colors.teal;
        break;

      case "OutForDelivery":
        icon = Icons.local_shipping;
        color = Colors.green;
        break;

      case "Delivered":
        icon = Icons.check_circle;
        color = Colors.green;
        break;

      default:
        icon = Icons.cancel;
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(30),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(
            icon,
            size: 18,
            color: color,
          ),

          const SizedBox(width: 6),

          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
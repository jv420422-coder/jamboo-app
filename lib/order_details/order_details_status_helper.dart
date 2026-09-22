import 'package:flutter/material.dart';

class OrderDetailsStatusHelper {
  const OrderDetailsStatusHelper._();

  static Color statusColor(String orderStatus) {
  final status = orderStatus.trim().toLowerCase();

  switch (status) {
      case "pending":
        return Colors.orange;

      case "accepted":
        return Colors.blue;

      case "preparing":
        return Colors.deepPurple;

      case "ready":
        return Colors.indigo;

      case "pickedup":
        return Colors.teal;

      case "outfordelivery":
        return Colors.green;

      case "delivered":
        return Colors.green;

      case "cancelled":
        return Colors.red;

      default:
        return Colors.deepPurple;
    }
  }

  static String statusTitle(String orderStatus) {
  final status = orderStatus.trim().toLowerCase();

  switch (status) {
      case "pending":
        return "Order Received";

      case "accepted":
        return "Restaurant Accepted";

      case "preparing":
        return "Preparing Food";

      case "ready":
        return "Ready For Pickup";

      case "pickedup":
        return "Picked Up";

      case "outfordelivery":
        return "On The Way";

      case "delivered":
        return "Delivered";

      case "cancelled":
        return "Order Cancelled";

      default:
        return "Processing";
    }
  }

  static String statusMessage(String orderStatus) {
  final status = orderStatus.trim().toLowerCase();

  switch (status) {
      case "pending":
        return "Your restaurant has received the order.";

      case "accepted":
        return "Restaurant accepted your order.";

      case "preparing":
        return "Our chefs are preparing your delicious meal.";

      case "ready":
        return "Your order is packed and ready.";

      case "pickedup":
        return "Delivery partner picked your order.";

      case "outfordelivery":
        return "Your food is almost there.";

      case "delivered":
        return "Enjoy your delicious meal.";

      case "cancelled":
        return "This order has been cancelled.";

      default:
        return "";
    }
  }

  static IconData statusIcon(String orderStatus) {
  final status = orderStatus.trim().toLowerCase();

  switch (status) {
      case "pending":
        return Icons.receipt_long;

      case "accepted":
        return Icons.check_circle;

      case "preparing":
        return Icons.restaurant;

      case "ready":
        return Icons.inventory;

      case "pickedup":
        return Icons.delivery_dining;

      case "outfordelivery":
        return Icons.local_shipping;

      case "delivered":
        return Icons.celebration;

      case "cancelled":
        return Icons.cancel;

      default:
        return Icons.restaurant;
    }
  }

  static bool canCancelOrder({
    required DateTime createdAt,
    required String orderStatus,
  }) {
    final difference = DateTime.now().difference(createdAt);

    return difference.inMinutes < 2 &&
        orderStatus != "Cancelled";
  }

  static Widget journeyStep({
    required String emoji,
    required String title,
    required bool completed,
    required Color statusColor,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor:
              completed ? statusColor : Colors.grey.shade300,
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
import 'package:flutter/material.dart';

class OrderDetailsStatusHelper {
  const OrderDetailsStatusHelper._();

  static Color statusColor(String orderStatus) {
    switch (orderStatus) {
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

  static String statusTitle(String orderStatus) {
    switch (orderStatus) {
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

  static String statusMessage(String orderStatus) {
    switch (orderStatus) {
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

  static IconData statusIcon(String orderStatus) {
    switch (orderStatus) {
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
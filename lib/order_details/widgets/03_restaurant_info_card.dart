import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';

class RestaurantInfoCard extends StatelessWidget {
  final OrderModel order;

  const RestaurantInfoCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.restaurantName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
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
                "Order #${order.orderNumber}",
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
                  order.createdAt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
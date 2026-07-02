import 'package:flutter/material.dart';
import '../../models/order_model.dart';

class DeliveryAddressCard extends StatelessWidget {
  final OrderModel order;

  const DeliveryAddressCard({
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
          const Text(
            "Delivery Address",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            order.deliveryAddress["fullName"] ?? "",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            order.deliveryAddress["phone"] ?? "",
          ),

          const SizedBox(height: 6),

          Text(
            "${order.deliveryAddress["address"]}\n${order.deliveryAddress["city"]}",
          ),
        ],
      ),
    );
  }
}
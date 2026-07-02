import 'package:flutter/material.dart';

class DeliveryTimeline extends StatelessWidget {
  final Color statusColor;
  final String orderStatus;
  final Widget Function(
    String emoji,
    String title,
    bool completed,
  ) journeyStep;

  const DeliveryTimeline({
    super.key,
    required this.statusColor,
    required this.orderStatus,
    required this.journeyStep,
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
            "Delivery Journey",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
                orderStatus != "Pending",
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
                orderStatus == "PickedUp" ||
                    orderStatus == "OutForDelivery" ||
                    orderStatus == "Delivered",
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
                orderStatus == "Delivered",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
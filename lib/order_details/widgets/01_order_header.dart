import 'package:flutter/material.dart';

class OrderHeader extends StatelessWidget {
  final Color statusColor;
  final IconData statusIcon;
  final String statusTitle;
  final String statusMessage;

  const OrderHeader({
    super.key,
    required this.statusColor,
    required this.statusIcon,
    required this.statusTitle,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(14),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
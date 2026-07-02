import 'package:flutter/material.dart';
import '../../models/order_model.dart';

class BillSummaryCard extends StatelessWidget {
  final OrderModel order;

  const BillSummaryCard({
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
        children: [
          billRow(
            "Items Total",
            "₹${order.subtotal.toStringAsFixed(0)}",
          ),

          billRow(
            "Delivery Fee",
            "₹${order.deliveryFee.toStringAsFixed(0)}",
          ),

          billRow(
            "Discount",
            "-₹${order.discount.toStringAsFixed(0)}",
          ),

          const Divider(),

          billRow(
            "Grand Total",
            "₹${order.totalAmount.toStringAsFixed(0)}",
            bold: true,
          ),
        ],
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
}
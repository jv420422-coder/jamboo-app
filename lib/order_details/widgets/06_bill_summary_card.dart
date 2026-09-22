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
    final paymentMethod =
        order.paymentMethod.trim().isEmpty
            ? "Payment"
            : order.paymentMethod;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF7E57C2),
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                "Bill Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF171717),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _billRow(
            "Item Total",
            "₹${order.subtotal.toStringAsFixed(0)}",
          ),

          _billRow(
            "Delivery Fee",
            "₹${order.deliveryFee.toStringAsFixed(0)}",
          ),

          _billRow(
            "Platform Fee",
            "₹${order.platformFee.toStringAsFixed(0)}",
          ),

          _billRow(
            "Discount",
            "-₹${order.discount.toStringAsFixed(0)}",
            valueColor: Colors.green,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 5,
            ),
            child: Divider(
              height: 1,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 7,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Grand Total",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF171717),
                    ),
                  ),
                ),
                Text(
                  "₹${order.totalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF171717),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EE),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Payment Method",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatPaymentMethod(
                          paymentMethod,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF171717),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black54,
                  size: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color:
                  valueColor ?? Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(
    String value,
  ) {
    final normalized =
        value
            .toLowerCase()
            .replaceAll("_", " ")
            .replaceAll("-", " ")
            .trim();

    if (normalized == "cod" ||
        normalized == "cash on delivery") {
      return "Cash on Delivery";
    }

    if (normalized == "online" ||
        normalized == "online payment" ||
        normalized == "razorpay" ||
        normalized == "upi") {
      return "Online Payment";
    }

    if (value.isEmpty) {
      return "Payment";
    }

    return value;
  }
}
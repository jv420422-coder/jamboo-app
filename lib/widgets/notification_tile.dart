import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  IconData get notificationIcon {
    switch (notification.type) {
      case "OrderPlaced":
        return Icons.receipt_long_rounded;

      case "Accepted":
        return Icons.restaurant_rounded;

      case "Preparing":
        return Icons.restaurant_menu_rounded;

      case "Ready":
        return Icons.inventory_2_rounded;

      case "OutForDelivery":
        return Icons.delivery_dining_rounded;

      case "Delivered":
        return Icons.check_circle_rounded;

      case "Cancelled":
        return Icons.cancel_rounded;

      case "Offer":
        return Icons.local_offer_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  Color get iconColor {
    switch (notification.type) {
      case "Cancelled":
        return Colors.red;

      case "Delivered":
        return Colors.green;

      case "Offer":
        return Colors.orange;

      default:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : Colors.deepPurple.shade100,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color:
                    iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notificationIcon,
                color: iconColor,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 16,
                            color:
                                notification.isRead
                                    ? Colors.black87
                                    : Colors.black,
                          ),
                        ),
                      ),

                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration:
                              const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    DateFormat(
                      "dd MMM yyyy • hh:mm a",
                    ).format(
                      notification.createdAt,
                    ),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
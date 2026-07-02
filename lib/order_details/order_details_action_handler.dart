import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../models/reorder_result.dart';

import '../services/order_service.dart';
import '../services/cart_service.dart';

import '../screens/cart/cart_screen.dart';
import '../screens/rating_screen.dart';

class OrderDetailsActionHandler {
  const OrderDetailsActionHandler._();

  // =========================
  // Cancel Order
  // =========================

  static Future<void> cancelOrder({
    required BuildContext context,
    required OrderModel order,
    required OrderService orderService,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Cancel Order",
          ),

          content: const Text(
            "Are you sure you want to cancel this order?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              child: const Text(
                "No",
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await orderService.cancelOrder(
                  orderId: order.orderId,
                  cancelledBy: "customer",
                );

                if (!context.mounted) return;

                Navigator.pop(
                  context,
                  true,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Order cancelled successfully",
                    ),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              child: const Text(
                "Yes, Cancel",
              ),
            ),
          ],
        );
      },
    );
  }
  // =========================
  // Rating
  // =========================

  static Future<void> openRatingScreen({
    required BuildContext context,
    required OrderModel order,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          orderId: order.orderId,
          orderNumber: order.orderNumber,
          restaurantId: order.restaurantId,
          restaurantName: order.restaurantName,
        ),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.pop(
        context,
        true,
      );
    }
  }
  // =========================
  // Reorder
  // =========================

  static Future<void> reorderOrder({
    required BuildContext context,
    required OrderModel order,
    required CartService cartService,
    required bool isReordering,
    required VoidCallback startLoading,
    required VoidCallback stopLoading,
  }) async {
    if (isReordering) return;

    startLoading();

    final result = await cartService.reorderOrder(
      restaurantId: order.restaurantId,
      orderItems: order.items,
    );

    if (!context.mounted) return;

    switch (result) {
      case ReorderResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Previous order added to your cart.",
            ),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CartScreen(),
          ),
        );

        break;

      case ReorderResult.differentRestaurant:
        await _showReplaceCartDialog(
          context: context,
          order: order,
          cartService: cartService,
        );
        break;

      case ReorderResult.unavailableItems:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Some items are unavailable.",
            ),
          ),
        );
        break;

      case ReorderResult.noItemsAvailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No items are available.",
            ),
          ),
        );
        break;
    }

    stopLoading();
  }
  static Future<void> _showReplaceCartDialog({
    required BuildContext context,
    required OrderModel order,
    required CartService cartService,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Replace Cart?",
          ),
          content: const Text(
            "Your cart contains items from another restaurant.\n\nDo you want to clear your current cart and reorder this order?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await cartService.clearCart();

                final result =
                    await cartService.reorderOrder(
                  restaurantId: order.restaurantId,
                  orderItems: order.items,
                );

                if (!context.mounted) return;

                if (result ==
                    ReorderResult.success) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CartScreen(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Reorder failed.",
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                "Clear Cart",
              ),
            ),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';

class OrderActionButtons extends StatelessWidget {
  final bool canCancelOrder;
  final bool showRatingButton;
  final bool showReorderButton;
  final bool isReordering;

  final VoidCallback onCancel;
  final VoidCallback onRate;
  final VoidCallback onReorder;

  const OrderActionButtons({
    super.key,
    required this.canCancelOrder,
    required this.showRatingButton,
    required this.showReorderButton,
    required this.isReordering,
    required this.onCancel,
    required this.onRate,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        if (canCancelOrder) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel Order"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],

        if (showRatingButton) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: onRate,
              icon: const Icon(Icons.star),
              label: const Text("Rate Restaurant"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],

        if (showReorderButton)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: isReordering ? null : onReorder,

              icon: isReordering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),

              label: Text(
                isReordering
                    ? "Reordering..."
                    : "Reorder",
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
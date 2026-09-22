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
          _actionButton(
            onPressed: onCancel,
            icon: Icons.close_rounded,
            label: "Cancel Order",
            backgroundColor: const Color(0xFFFFF1F1),
            foregroundColor: Colors.red,
            borderColor: const Color(0xFFFFD6D6),
          ),
          const SizedBox(height: 10),
        ],

        if (showRatingButton) ...[
          _actionButton(
            onPressed: onRate,
            icon: Icons.star_rounded,
            label: "Rate Our Service",
            backgroundColor: const Color(0xFFFFF8E6),
            foregroundColor: const Color(0xFFE29A00),
            borderColor: const Color(0xFFFFE5A8),
          ),
          const SizedBox(height: 10),
        ],

        if (showReorderButton)
          _actionButton(
            onPressed: isReordering ? null : onReorder,
            icon: isReordering
                ? Icons.hourglass_top_rounded
                : Icons.refresh_rounded,
            label: isReordering ? "Reordering..." : "Reorder",
            backgroundColor: const Color(0xFFF3EEFF),
            foregroundColor: const Color(0xFF7E57C2),
            borderColor: const Color(0xFFE1D4FF),
            isLoading: isReordering,
          ),
      ],
    );
  }

  Widget _actionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor,
                  ),
                ),
              )
            : Icon(
                icon,
                size: 19,
              ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
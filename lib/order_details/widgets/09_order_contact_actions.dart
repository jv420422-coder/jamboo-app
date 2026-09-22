import 'package:flutter/material.dart';

class OrderContactActions extends StatelessWidget {
  final bool showRestaurantButton;
  final bool showRiderButton;

  final VoidCallback onCallRestaurant;
  final VoidCallback onCallRider;
  final VoidCallback onLeaveNote;

  final String riderName;
  final String riderPhone;
  final String vehicleNumber;

  const OrderContactActions({
    super.key,
    required this.showRestaurantButton,
    required this.showRiderButton,
    required this.riderName,
    required this.riderPhone,
    required this.vehicleNumber,
    required this.onCallRestaurant,
    required this.onCallRider,
    required this.onLeaveNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFF7E57C2),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                "Support",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF171717),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            "Contact the restaurant or delivery partner if you need assistance.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          if (showRestaurantButton)
            _actionButton(
              icon: Icons.restaurant_rounded,
              label: "Call Restaurant",
              onPressed: onCallRestaurant,
              backgroundColor: const Color(0xFFF3EEFF),
              iconColor: const Color(0xFF7E57C2),
            ),

          if (showRestaurantButton && showRiderButton)
            const SizedBox(height: 10),

          if (showRiderButton) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE8DFFF),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: Color(0xFF7E57C2),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riderName.isEmpty
                              ? "Delivery Partner"
                              : riderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF171717),
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (vehicleNumber.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.two_wheeler_rounded,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  vehicleNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        if (riderPhone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                riderPhone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            _actionButton(
              icon: Icons.call_rounded,
              label: "Call Delivery Partner",
              onPressed: onCallRider,
              backgroundColor: const Color(0xFFF3EEFF),
              iconColor: const Color(0xFF7E57C2),
            ),
          ],

          if (showRestaurantButton || showRiderButton)
            const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onLeaveNote,
              icon: const Icon(
                Icons.sticky_note_2_outlined,
                size: 19,
              ),
              label: const Text(
                "Leave a Note",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7E57C2),
                side: const BorderSide(
                  color: Color(0xFFDCCEFF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: iconColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
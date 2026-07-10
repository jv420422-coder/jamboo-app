import 'package:flutter/material.dart';

class OrderContactActions extends StatelessWidget {
  final bool showRestaurantButton;
  final bool showRiderButton;

  final VoidCallback onCallRestaurant;
  final VoidCallback onCallRider;
  final VoidCallback onLeaveNote;

  const OrderContactActions({
    super.key,
    required this.showRestaurantButton,
    required this.showRiderButton,
    required this.onCallRestaurant,
    required this.onCallRider,
    required this.onLeaveNote,
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
            "Support",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Contact the restaurant or delivery partner if you need assistance.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          if (showRestaurantButton)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onCallRestaurant,
                icon: const Icon(Icons.call),
                label: const Text("Call Restaurant"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          if (showRestaurantButton)
            const SizedBox(height: 12),

          if (showRiderButton)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onCallRider,
                icon: const Icon(Icons.delivery_dining),
                label: const Text("Call Rider"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          if (showRiderButton)
            const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onLeaveNote,
              icon: const Icon(Icons.sticky_note_2),
              label: const Text("Leave a Note"),
            ),
          ),
        ],
      ),
    );
  }
}
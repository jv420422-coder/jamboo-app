import 'package:flutter/material.dart';
import '../screens/saved_addresses_screen.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const SavedAddressesScreen(),
                ),
              );
            },
            child: const Row(
              children: [

                Icon(
                  Icons.location_on,
                  color: Color(0xFF7E57C2),
                ),

                SizedBox(width: 5),

                Text(
                  "Chauri Chaura",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.notifications_none,
          ),
        ],
      ),
    );
  }
}
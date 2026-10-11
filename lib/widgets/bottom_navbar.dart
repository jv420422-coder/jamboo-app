import 'package:flutter/material.dart';

import '../services/cart_service.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final CartService cartService = CartService();

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF7E57C2),
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
          ),
          label: "Home",
        ),

        const BottomNavigationBarItem(
          icon: Icon(
            Icons.local_fire_department,
          ),
          label: "Under ₹199",
        ),

        BottomNavigationBarItem(
          icon: StreamBuilder<int>(
            stream: cartService.totalItems(),
            builder: (context, snapshot) {
              final int count = snapshot.data ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                  ),

                  if (count > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        constraints:
                            const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          count > 99
                              ? "99+"
                              : count.toString(),
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: "Cart",
        ),

        const BottomNavigationBarItem(
          icon: Icon(
            Icons.person_outline,
          ),
          label: "Profile",
        ),
      ],
    );
  }
}
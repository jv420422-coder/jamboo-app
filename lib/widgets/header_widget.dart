import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../screens/saved_addresses_screen.dart';
import '../services/notification_service.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    final notificationService =
        NotificationService();

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
                  builder: (_) =>
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

          StreamBuilder<int>(
            stream: notificationService
                .unreadCount(uid),

            builder: (context, snapshot) {

              final unread =
                  snapshot.data ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [

                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 30,
                    ),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const NotificationsScreen(),
                        ),
                      );
                    },
                  ),

                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,

                      child: Container(
                        padding:
                            const EdgeInsets.all(5),

                        decoration:
                            const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),

                        constraints:
                            const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),

                        child: Center(
                          child: Text(
                            unread > 99
                                ? "99+"
                                : unread
                                    .toString(),

                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
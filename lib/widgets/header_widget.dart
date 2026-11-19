import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../screens/saved_addresses_screen.dart';
import '../services/notification_service.dart';

class HeaderWidget extends StatelessWidget {
  final VoidCallback? onLocationTap;
  final String? currentAddress;

  const HeaderWidget({
    super.key,
    this.onLocationTap,
    this.currentAddress,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final notificationService = NotificationService();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // CURRENT LOCATION
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (onLocationTap != null) {
                  onLocationTap!();
                } else if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SavedAddressesScreen(),
                    ),
                  );
                }
              },
              child: user != null
                  ? StreamBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String locationText =
                            'Getting location...';

                        if (snapshot.hasData &&
                            snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data();

                          final address = data?[
                                  'currentAddress']
                              ?.toString()
                              .trim();

                          if (address != null &&
                              address.isNotEmpty) {
                            locationText = address;
                          }
                        }

                        return _buildLocationRow(
                          locationText,
                        );
                      },
                    )
                  : _buildLocationRow(
                      currentAddress?.trim().isNotEmpty ==
                              true
                          ? currentAddress!.trim()
                          : 'Getting location...',
                    ),
            ),
          ),

          // NOTIFICATIONS - ONLY LOGGED-IN USERS
          if (user != null) ...[
            const SizedBox(width: 8),
            StreamBuilder<int>(
              stream: notificationService.unreadCount(
                user.uid,
              ),
              builder: (context, snapshot) {
                final unread = snapshot.data ?? 0;

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
                          decoration: const BoxDecoration(
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
                                  : unread.toString(),
                              style: const TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildLocationRow(String locationText) {
    return Row(
      children: [
        const Icon(
          Icons.location_on,
          color: Color(0xFF7E57C2),
          size: 27,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            locationText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
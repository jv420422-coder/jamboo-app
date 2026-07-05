import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final NotificationService
      _notificationService =
      NotificationService();

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F0FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Mark all as read",
            icon: const Icon(
              Icons.done_all,
              color: Colors.deepPurple,
            ),
            onPressed: () async {
              await _notificationService
                  .markAllAsRead(
                userId: uid,
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationService
            .getUserNotifications(uid),

        builder: (context, snapshot) {
            if (snapshot.hasError) {
  print("❌ Notification Stream Error");
  print(snapshot.error);

  return Center(
    child: Text(
      snapshot.error.toString(),
    ),
  );
}
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 90,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "No Notifications",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "You'll receive order updates and offers here.",
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications =
              snapshot.data!.docs;

          return ListView.builder(
            padding:
                const EdgeInsets.all(20),
            itemCount:
                notifications.length,

            itemBuilder:
                (context, index) {
              final notification =
                  NotificationModel
                      .fromMap(
                notifications[index]
                    .data(),
              );

              return NotificationTile(
                notification:
                    notification,

                onTap: () async {
                  if (!notification
                      .isRead) {
                    await _notificationService
                        .markAsRead(
                      notificationId:
                          notification
                              .notificationId,
                    );
                  }

                  // Future:
                  // Order notification →
                  // Open Order Details
                  //
                  // Offer notification →
                  // Open Offers Screen
                },
              );
            },
          );
        },
      ),
    );
  }
}
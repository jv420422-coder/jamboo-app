import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

class NotificationService {
  NotificationService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _notifications =>
          _firestore.collection("notifications");

  // ==========================
  // Create Notification
  // ==========================

  Future<void> createNotification({
    required NotificationModel notification,
  }) async {
    await _notifications
        .doc(notification.notificationId)
        .set(notification.toMap());
  }

  // ==========================
  // User Notifications Stream
  // ==========================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getUserNotifications(
    String userId,
  ) {
    return _notifications
        .where(
          "userId",
          isEqualTo: userId,
        )
        .orderBy(
          "createdAt",
          descending: true,
        )
        .snapshots();
  }

  // ==========================
  // Mark Notification As Read
  // ==========================

  Future<void> markAsRead({
    required String notificationId,
  }) async {
    await _notifications
        .doc(notificationId)
        .update({
      "isRead": true,
    });
  }

  // ==========================
  // Mark All Notifications Read
  // ==========================

  Future<void> markAllAsRead({
    required String userId,
  }) async {
    final snapshot = await _notifications
        .where(
          "userId",
          isEqualTo: userId,
        )
        .where(
          "isRead",
          isEqualTo: false,
        )
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(
        doc.reference,
        {
          "isRead": true,
        },
      );
    }

    await batch.commit();
  }

  // ==========================
  // Delete Notification
  // ==========================

  Future<void> deleteNotification({
    required String notificationId,
  }) async {
    await _notifications
        .doc(notificationId)
        .delete();
  }

  // ==========================
  // Delete All Notifications
  // ==========================

  Future<void> deleteAllNotifications({
    required String userId,
  }) async {
    final snapshot = await _notifications
        .where(
          "userId",
          isEqualTo: userId,
        )
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ==========================
  // Unread Notification Count
  // ==========================

  Stream<int> unreadCount(
    String userId,
  ) {
    return _notifications
        .where(
          "userId",
          isEqualTo: userId,
        )
        .where(
          "isRead",
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }
}
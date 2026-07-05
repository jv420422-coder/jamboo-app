class NotificationModel {
  final String notificationId;

  final String userId;

  final String title;

  final String message;

  final String type;

  final bool isRead;

  final DateTime createdAt;

  final String? orderId;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.orderId,
  });
  Map<String, dynamic> toMap() {
  return {
    "notificationId": notificationId,
    "userId": userId,
    "title": title,
    "message": message,
    "type": type,
    "isRead": isRead,
    "createdAt": createdAt,
    "orderId": orderId,
  };
}

factory NotificationModel.fromMap(
  Map<String, dynamic> map,
) {
  return NotificationModel(
    notificationId:
        map["notificationId"] ?? "",

    userId:
        map["userId"] ?? "",

    title:
        map["title"] ?? "",

    message:
        map["message"] ?? "",

    type:
        map["type"] ?? "",

    isRead:
        map["isRead"] ?? false,

    createdAt:
        map["createdAt"].toDate(),

    orderId:
        map["orderId"],
  );
}
}
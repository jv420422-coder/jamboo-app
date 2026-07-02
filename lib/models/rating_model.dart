class RatingModel {
  final String ratingId;
  final String orderId;
  final String orderNumber;
  final String restaurantId;
  final String restaurantName;
  final String customerId;
  final String customerName;
  final double rating;
  final String review;
  final DateTime createdAt;

  RatingModel({
    required this.ratingId,
    required this.orderId,
    required this.orderNumber,
    required this.restaurantId,
    required this.restaurantName,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "ratingId": ratingId,
      "orderId": orderId,
      "restaurantId": restaurantId,
      "customerId": customerId,
      "rating": rating,
      "review": review,
      "createdAt": createdAt,
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      ratingId: map["ratingId"],
      orderId: map["orderId"],
      restaurantId: map["restaurantId"],
      customerId: map["customerId"],
      rating: (map["rating"] as num).toDouble(),
      review: map["review"] ?? "",
      createdAt: map["createdAt"].toDate(),
      orderNumber: map["orderNumber"] ?? "",
restaurantName: map["restaurantName"] ?? "",
customerName: map["customerName"] ?? "",
    );
  }
}
class CartItemModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String itemName;
  final String description;
  final double price;
  final int quantity;
  final String emoji;
  final String imageUrl;

  // Preparation
  final int preparationTime;

  CartItemModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.itemName,
    required this.description,
    required this.price,
    required this.quantity,
    required this.emoji,
    this.imageUrl = "",
    required this.preparationTime,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "restaurantId": restaurantId,
      "restaurantName": restaurantName,
      "itemName": itemName,
      "description": description,
      "price": price,
      "quantity": quantity,
      "emoji": emoji,
      "imageUrl": imageUrl,

      // Preparation time snapshot
      "preparationTime": preparationTime,
    };
  }

  factory CartItemModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return CartItemModel(
      id: map["id"] ?? "",
      restaurantId: map["restaurantId"] ?? "",
      restaurantName: map["restaurantName"] ?? "",
      itemName: map["itemName"] ?? "",
      description: map["description"] ?? "",
      price: (map["price"] ?? 0).toDouble(),
      quantity: map["quantity"] ?? 1,
      emoji: map["emoji"] ?? "🍽️",
      imageUrl: map["imageUrl"] ?? "",

      // Old cart items ke liye default 20 minutes
      preparationTime:
          (map["preparationTime"] ?? 20).toInt(),
    );
  }
}
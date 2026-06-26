class CartItemModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String itemName;
  final String description;
  final double price;
  final int quantity;
  final String emoji;

  CartItemModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.itemName,
    required this.description,
    required this.price,
    required this.quantity,
    required this.emoji,
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
    };
  }

  factory CartItemModel.fromMap(
      Map<String, dynamic> map) {
    return CartItemModel(
      id: map["id"],
      restaurantId: map["restaurantId"],
      restaurantName: map["restaurantName"],
      itemName: map["itemName"],
      description: map["description"],
      price: (map["price"] as num).toDouble(),
      quantity: map["quantity"],
      emoji: map["emoji"],
    );
  }
}
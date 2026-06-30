import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';
import '../models/reorder_result.dart';

class CartService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final String uid =
      FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get cartRef =>
      _firestore
          .collection("users")
          .doc(uid)
          .collection("cart");

  Future<void> addToCart(CartItemModel item) async {
    final doc = cartRef.doc(item.id);

    final existing = await doc.get();

    if (existing.exists) {
      final data =
          existing.data() as Map<String, dynamic>;

      await doc.update({
        "quantity": (data["quantity"] ?? 0) + 1,
      });

    } else {

      await doc.set(item.toMap());

    }
  }

  Future<void> increaseQty(String id) async {

    final doc = await cartRef.doc(id).get();

    final data =
        doc.data() as Map<String, dynamic>;

    await cartRef.doc(id).update({
      "quantity": (data["quantity"] ?? 0) + 1,
    });

  }

  Future<void> decreaseQty(String id) async {

    final doc = await cartRef.doc(id).get();

    final data =
        doc.data() as Map<String, dynamic>;

    int qty = data["quantity"];

    if (qty <= 1) {

      await cartRef.doc(id).delete();

    } else {

      await cartRef.doc(id).update({
        "quantity": qty - 1,
      });

    }

  }

  Future<void> removeItem(String id) async {

    await cartRef.doc(id).delete();

  }

  Stream<QuerySnapshot> cartStream() {

    return cartRef.snapshots();

  }

  Stream<int> totalItems() {

    return cartRef.snapshots().map((snapshot) {

      int total = 0;

      for (var doc in snapshot.docs) {

        final data =
            doc.data() as Map<String, dynamic>;

        total +=
            (data["quantity"] ?? 0) as int;

      }

      return total;

    });

  }

  Stream<double> totalPrice() {

    return cartRef.snapshots().map((snapshot) {

      double total = 0;

      for (var doc in snapshot.docs) {

        final data =
            doc.data() as Map<String, dynamic>;

        total +=
            ((data["price"] ?? 0) as num)
                .toDouble() *
            ((data["quantity"] ?? 0) as int);

      }

      return total;

    });

  }
  Future<void> clearCart() async {

  final snapshot = await cartRef.get();

  final batch = _firestore.batch();

  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
  }

  await batch.commit();

}

Future<void> addOrderItemToCart(
  CartItemModel item,
) async {

  final doc = cartRef.doc(item.id);

  final existing = await doc.get();

  if (existing.exists) {

    final data =
        existing.data() as Map<String, dynamic>;

    await doc.update({

      "quantity":
          (data["quantity"] ?? 0) +
          item.quantity,

    });

  } else {

    await doc.set(item.toMap());

  }
}
  
Future<ReorderResult> reorderOrder({
  required String restaurantId,
  required List<Map<String, dynamic>> orderItems,
}) async {

  // Current cart
  final cartSnapshot = await cartRef.get();

  // Check current restaurant in cart
  if (cartSnapshot.docs.isNotEmpty) {

    final cartData =
        cartSnapshot.docs.first.data()
            as Map<String, dynamic>;

    final currentRestaurantId =
        cartData["restaurantId"] ?? "";

    if (currentRestaurantId != restaurantId) {
      return ReorderResult.differentRestaurant;
    }
  }

  // Available menu items
  final List<CartItemModel> availableItems = [];

  for (final item in orderItems) {

    final itemId = item["id"];

    final menuDoc = await FirebaseFirestore.instance
        .collection("menu_items")
        .doc(itemId)
        .get();

    // Item deleted
    if (!menuDoc.exists) {
      continue;
    }

    final menuData =
        menuDoc.data() as Map<String, dynamic>;

    // Item unavailable
    if (menuData["isAvailable"] != true) {
      continue;
    }

    availableItems.add(
      CartItemModel(
        id: itemId,
        restaurantId: menuData["restaurantId"],
        restaurantName: item["restaurantName"],
        itemName: menuData["name"],
        description: menuData["description"],
        price:
            (menuData["price"] as num).toDouble(),
        quantity: item["quantity"],
        emoji: menuData["emoji"] ?? "🍽️",
      ),
    );
  }

  // Nothing available
if (availableItems.isEmpty) {
  return ReorderResult.noItemsAvailable;
}

for (final item in availableItems) {
  await addOrderItemToCart(item);
}

if (availableItems.length < orderItems.length) {
  return ReorderResult.unavailableItems;
}

return ReorderResult.success;
}
}
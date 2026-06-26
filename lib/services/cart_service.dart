import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';

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
}
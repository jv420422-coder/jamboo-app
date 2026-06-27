import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/address_model.dart';

class AddressService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final String uid =
      FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get addressRef =>
      _firestore
          .collection("users")
          .doc(uid)
          .collection("addresses");

  Future<void> saveAddress(
    AddressModel address,
  ) async {
    await addressRef
        .doc(address.id)
        .set(address.toMap());
  }

  Future<void> updateAddress(
    AddressModel address,
  ) async {
    await addressRef
        .doc(address.id)
        .update(address.toMap());
  }

  Future<void> deleteAddress(
    String id,
  ) async {
    await addressRef
        .doc(id)
        .delete();
  }

  Stream<QuerySnapshot> addressStream() {
    return addressRef.snapshots();
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_new_address_screen.dart';
import 'payment_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  final bool isCheckoutMode;

  const SavedAddressesScreen({
    super.key,
    this.isCheckoutMode = false,
  });

  @override
  State<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState
    extends State<SavedAddressesScreen> {

  String? selectedAddressId;

  @override
  Widget build(BuildContext context) {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "📍 Saved Addresses",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            Expanded(
              child: StreamBuilder<QuerySnapshot>(

                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .collection("addresses")
                    .orderBy(
                      "createdAt",
                      descending: true,
                    )
                    .snapshots(),

                builder: (context, snapshot) {

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {

                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {

                    return const Center(
                      child: Text(
                        "No Saved Address",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(

                    itemCount: docs.length,

                    itemBuilder: (context, index) {

                      final data =
                          docs[index].data()
                              as Map<String, dynamic>;
return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAddressId = docs[index].id;
                          });
                        },

                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: 15,
                          ),

                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius:
                                BorderRadius.circular(16),

                            border: Border.all(
                              color:
                                  selectedAddressId ==
                                          docs[index].id
                                      ? Colors.deepPurple
                                      : Colors.transparent,
                              width: 2,
                            ),

                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                              ),
                            ],
                          ),

                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    Text(
                                      data["type"] ==
                                              "Home"
                                          ? "🏠 Home"
                                          : data["type"] ==
                                                  "Work"
                                              ? "🏢 Work"
                                              : "📍 Other",

                                      style:
                                          const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    if (data["isDefault"] ==
                                        true) ...[
                                      const SizedBox(
                                          height: 6),

                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),

                                        decoration:
                                            BoxDecoration(
                                          color:
                                              Colors.green,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      20),
                                        ),

                                        child: const Text(
                                          "⭐ DEFAULT",
                                          style:
                                              TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 8),
                                    ],

                                    Text(
                                      data["fullName"] ??
                                          "",
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 4),

                                    Text(
                                      data["phone"] ??
                                          "",
                                    ),

                                    const SizedBox(
                                        height: 4),

                                    Text(
                                      data["address"] ??
                                          "",
                                    ),

                                    if ((data["landmark"] ??
                                            "")
                                        .toString()
                                        .isNotEmpty) ...[
                                      const SizedBox(
                                          height: 4),

                                      Text(
                                        "Landmark: ${data["landmark"]}",
                                      ),
                                    ],

                                    const SizedBox(
                                        height: 4),

                                    Text(
                                      "${data["city"]}, ${data["state"]} - ${data["pincode"]}",
                                    ),
                                  ],
                                ),
                              ),

                              PopupMenuButton<String>(
                                onSelected:
                                    (value) async {

                                  if (value ==
                                      "edit") {

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AddNewAddressScreen(
                                          documentId:
                                              docs[index]
                                                  .id,
                                          addressData:
                                              data,
                                        ),
                                      ),
                                    );

                                    return;
                                  }

                                  if (value ==
                                      "default") {

                                    final batch =
                                        FirebaseFirestore
                                            .instance
                                            .batch();

                                    for (final doc
                                        in docs) {
                                      batch.update(
                                        doc.reference,
                                        {
                                          "isDefault":
                                              false,
                                        },
                                      );
                                    }

                                    batch.update(
                                      docs[index]
                                          .reference,
                                      {
                                        "isDefault":
                                            true,
                                      },
                                    );

                                    await batch.commit();

                                    return;
                                  }

                                  if (value ==
                                      "delete") {

                                    await docs[index]
                                        .reference
                                        .delete();
                                  }
                                },

                                itemBuilder:
                                    (context) =>
                                        const [

                                  PopupMenuItem(
                                    value: "edit",
                                    child: Text(
                                        "✏️ Edit"),
                                  ),

                                  PopupMenuItem(
                                    value:
                                        "default",
                                    child: Text(
                                        "⭐ Set Default"),
                                  ),

                                  PopupMenuItem(
                                    value:
                                        "delete",
                                    child: Text(
                                        "🗑 Delete"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
},
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AddNewAddressScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.add_location_alt,
                ),
                label: const Text(
                  "Add New Address",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepPurple,
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ),

            if (widget.isCheckoutMode) ...[

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {

                    if (selectedAddressId == null) {

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select an address",
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PaymentScreen(),
                      ),
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.deepPurple,
                    foregroundColor:
                        Colors.white,
                  ),
                  child: const Text(
                    "Proceed to Payment",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            ],

          ],
        ),
      ),
    );
  }
}
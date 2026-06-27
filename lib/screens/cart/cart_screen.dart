import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';

import '../home_screen.dart';
import '../saved_addresses_screen.dart';
import '../payment_screen.dart';
import '../offers_coupons_screen.dart';

import 'cart_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() =>
      _CartScreenState();
}

class _CartScreenState
    extends State<CartScreen> {

  final CartService cartService =
      CartService();

  bool couponApplied = false;
  String? appliedCoupon;

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
      stream: cartService.cartStream(),

      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        List<CartItemModel> cartItems = [];

        double itemsTotal = 0;

        int totalItems = 0;

        for (var doc in docs) {

          final item =
              CartItemModel.fromMap(
            doc.data()
                as Map<String, dynamic>,
          );

          cartItems.add(item);

          totalItems += item.quantity;

          itemsTotal +=
              item.price * item.quantity;
        }

        double grandTotal =
            itemsTotal +
            30 +
            10 -
            (couponApplied ? 50 : 0);

        return Scaffold(

          backgroundColor:
              const Color(0xFFF5F0FF),

          appBar: AppBar(

            backgroundColor:
                const Color(0xFFF5F0FF),

            elevation: 0,

            title: const Text(
              "🛒 Your Cart",
              style: TextStyle(
                color: Colors.black,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

          ),

          body: totalItems == 0

              ? Center(

                  child: Column(

                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [

                      const Text(
                        "😕",
                        style: TextStyle(
                          fontSize: 80,
                        ),
                      ),

                      const SizedBox(
                          height: 16),

                      const Text(
                        "Your Cart Is Empty",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      const Text(
                        "Let's find something delicious",
                      ),

                      const SizedBox(
                          height: 24),

                      ElevatedButton(

                        onPressed: () {

                          Navigator.pushAndRemoveUntil(

                            context,

                            MaterialPageRoute(

                              builder: (_) =>
                                  const HomeScreen(),

                            ),

                            (route) => false,

                          );

                        },

                        child: const Text(
                          "Browse Food",
                        ),

                      ),

                    ],

                  ),

                )

              : SingleChildScrollView(
child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Column(
                      children: [

                        Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Row(
                            children: [

                              const Icon(
                                Icons.location_on,
                                color:
                                    Colors.deepPurple,
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    Text(
                                      "Deliver To",
                                      style: TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    SizedBox(height: 4),

                                    Text(
                                      "Jatin",
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      "Chauri Chaura, Gorakhpur",
                                    ),
                                  ],
                                ),
                              ),

                              TextButton(
                                onPressed: () {
                                  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        const SavedAddressesScreen(
          isCheckoutMode: true,
        ),
  ),
);
                                },
                                child: const Text(
                                  "Change",
                                ),
                              ),
                            ],
                          ),
                        ),

                        ...cartItems.map(
                          (item) => CartItemCard(
                            item: item,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Row(
                            children: [

                              const Icon(
                                Icons.local_offer,
                                color:
                                    Colors.deepPurple,
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [

                                    const Text(
                                      "Apply Coupon",
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      couponApplied
                                          ? "✅ JAMBOO50 Applied"
                                          : "Use JAMBOO50",
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      couponApplied
                                          ? "You saved ₹50"
                                          : "Save ₹50 instantly",
                                      style: const TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              TextButton(
                                onPressed: () async {

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const OffersCouponsScreen(),
    ),
  );

  if (result != null) {
    setState(() {
      appliedCoupon = result;
      couponApplied = result == "JAMBOO50";
    });
  }

},
                                child: Text(
                                  couponApplied
                                      ? "Change"
                                      : "View",
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
const Divider(),

                        BillRow(
                          title: "Items Total",
                          value:
                              "₹${itemsTotal.toStringAsFixed(0)}",
                        ),

                        if (couponApplied)
                          const BillRow(
                            title: "Coupon Discount",
                            value: "-₹50",
                          ),

                        const BillRow(
                          title: "Delivery Fee",
                          value: "₹30",
                        ),

                        const BillRow(
                          title: "Platform Fee",
                          value: "₹10",
                        ),

                        const Divider(),

                        BillRow(
                          title: "Grand Total",
                          value:
                              "₹${grandTotal.toStringAsFixed(0)}",
                          bold: true,
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
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
                              "Proceed to Checkout",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
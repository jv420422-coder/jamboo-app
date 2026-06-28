import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import 'order_success_screen.dart';


class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() =>
      _PaymentScreenState();
}

class _PaymentScreenState
    extends State<PaymentScreen> {

  final CartService _cartService =
      CartService();

  final OrderService _orderService =
      OrderService();

  String selectedPayment = "COD";

  bool isLoading = false;

  double deliveryFee = 30;
  double discount = 0;

  @override
  Widget build(BuildContext context) {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "💳 Payment",
          style: TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("addresses")
            .where("selectedForCheckout", isEqualTo: true)
            .limit(1)
            .snapshots(),

        builder: (context, addressSnapshot) {

          if (!addressSnapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          Map<String, dynamic>? address;

if (addressSnapshot.data!.docs.isNotEmpty) {
  address = addressSnapshot.data!.docs.first.data()
      as Map<String, dynamic>;
}

          return StreamBuilder<QuerySnapshot>(
            stream:
                _cartService.cartStream(),

            builder:
                (context, cartSnapshot) {

              if (!cartSnapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final cartDocs =
                  cartSnapshot.data!.docs;
if (cartDocs.isEmpty) {
                return const Center(
                  child: Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              double subtotal = 0;

              for (final doc in cartDocs) {
                final data =
                    doc.data() as Map<String, dynamic>;

                subtotal +=
                    ((data["price"] as num).toDouble()) *
                    ((data["quantity"] as int));
              }

              final total =
                  subtotal +
                  deliveryFee -
                  discount;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          const Text(
                            "📍 Deliver To",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (address != null) ...[

                            Text(
                              address["fullName"] ?? "",
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(
                              address["phone"] ?? "",
                            ),

                            const SizedBox(height: 5),

                            Text(
                              address["address"] ?? "",
                            ),

                            Text(
                              "${address["city"]}, ${address["state"]} - ${address["pincode"]}",
                            ),

                          ] else

                            const Text(
                              "No default address selected",
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Payment Method",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    paymentTile(
                      "Cash on Delivery",
                      "COD",
                      Icons.money,
                    ),

                    paymentTile(
                      "UPI",
                      "UPI",
                      Icons.account_balance,
                    ),

                    paymentTile(
                      "Credit / Debit Card",
                      "CARD",
                      Icons.credit_card,
                    ),

                    paymentTile(
                      "Wallet",
                      "WALLET",
                      Icons.account_balance_wallet,
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding:
                          const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      child: Column(
                        children: [

                          summaryRow(
                            "Item Total",
                            subtotal,
                          ),

                          summaryRow(
                            "Delivery Fee",
                            deliveryFee,
                          ),

                          summaryRow(
                            "Discount",
                            -discount,
                          ),

                          const Divider(),

                          summaryRow(
                            "Grand Total",
                            total,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {

                                setState(() {
                                  isLoading = true;
                                });

                                try {

                                  final orderId = FirebaseFirestore
                                      .instance
                                      .collection("orders")
                                      .doc()
                                      .id;

                                  final orderNumber =
                                      "JMB${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

                                  final List<Map<String, dynamic>>
                                      items = [];

                                  String restaurantId = "";
                                  String restaurantName = "";

                                  for (final doc in cartDocs) {

                                    final data = doc.data()
                                        as Map<String, dynamic>;

                                    items.add(data);

                                    restaurantId =
                                        data["restaurantId"] ?? "";

                                    restaurantName =
                                        data["restaurantName"] ?? "";
                                  }

                                  final order = OrderModel(
                                    orderId: orderId,
                                    orderNumber: orderNumber,
                                    userId: uid,
                                    restaurantId: restaurantId,
                                    restaurantName: restaurantName,
                                    items: items,
                                    deliveryAddress:
                                        address ?? {},
                                    paymentMethod:
                                        selectedPayment,
                                    paymentStatus: "Pending",
                                    orderStatus: "Pending",
                                    subtotal: subtotal,
                                    deliveryFee:
                                        deliveryFee,
                                    discount: discount,
                                    totalAmount: total,
                                    createdAt:
                                        DateTime.now(),
                                  );

                                  await _orderService
                                      .placeOrder(order);

                                  await _cartService
                                      .clearCart();
                                  

                                  if (!mounted) return;

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const OrderSuccessScreen(),
                                    ),
                                  );

                                } catch (e) {

                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString(),
                                      ),
                                    ),
                                  );

                                } finally {

                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }

                                }
                              },

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.deepPurple,
                          foregroundColor:
                              Colors.white,
                        ),

                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Place Order",
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
              );
            },
          );
        },
      ),
    );
  }

  Widget paymentTile(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedPayment,
        onChanged: (value) {
          setState(() {
            selectedPayment = value!;
          });
        },
        title: Text(title),
        secondary: Icon(
          icon,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget summaryRow(
    String title,
    double amount, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14,
              ),
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
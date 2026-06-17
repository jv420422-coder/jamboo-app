import 'package:flutter/material.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "📦 My Orders",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          orderCard(
            emoji: "🍕",
            title: "Cheese Pizza",
            orderId: "#JB12345",
            date: "12 Jun 2026",
            status: "Delivered ✅",
          ),

          orderCard(
            emoji: "🍔",
            title: "Veg Burger",
            orderId: "#JB12344",
            date: "10 Jun 2026",
            status: "Delivered ✅",
          ),

          orderCard(
            emoji: "🍛",
            title: "Special Biryani",
            orderId: "#JB12343",
            date: "08 Jun 2026",
            status: "Cancelled ❌",
          ),
        ],
      ),
    );
  }

  Widget orderCard({
    required String emoji,
    required String title,
    required String orderId,
    required String date,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Text(
                emoji,
                style: const TextStyle(
                  fontSize: 35,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    Text(orderId),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            "📅 $date",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            status,
            style: const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [

              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text(
                    "Track Order",
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.deepPurple,
                    foregroundColor:
                        Colors.white,
                  ),
                  child: const Text(
                    "Reorder",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
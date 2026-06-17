import 'package:flutter/material.dart';

class Under199Screen extends StatelessWidget {
  const Under199Screen({super.key});

  @override
  Widget build(BuildContext context) {

    final List<Map<String, dynamic>> allItems = [
      {
        "name": "Cheese Pizza",
        "restaurant": "Pizza Hub",
        "price": 199,
        "emoji": "🍕",
      },
      {
        "name": "Veg Burger",
        "restaurant": "Burger House",
        "price": 149,
        "emoji": "🍔",
      },
      {
        "name": "Veg Momos",
        "restaurant": "Momo Point",
        "price": 99,
        "emoji": "🥟",
      },
      {
        "name": "Special Biryani",
        "restaurant": "Biryani King",
        "price": 299,
        "emoji": "🍛",
      },
    ];

    final under199Items = allItems
        .where((item) => item["price"] <= 199)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "🔥 Under ₹199",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: under199Items.length,
        itemBuilder: (context, index) {

          final item = under199Items[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Row(
              children: [

                Text(
                  item["emoji"],
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
                        item["name"],
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        item["restaurant"],
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  "₹${item["price"]}",
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
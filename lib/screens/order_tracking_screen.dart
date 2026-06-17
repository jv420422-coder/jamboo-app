import 'package:flutter/material.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "📦 Track Order",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // Order ID Card
            Container(
              width: double.infinity,
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
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    "📦 Order #JB12345",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    "Your order is on the way!",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ordered Items
            Container(
              width: double.infinity,
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
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    "🍽 Ordered Items",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "🍕 Cheese Pizza x2",
                  ),

                  SizedBox(height: 8),

                  Text(
                    "🍔 Veg Burger x1",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tracking Status
            Container(
              width: double.infinity,
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
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    "🚚 Order Status",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 16),

                  Text(
                    "✅ Order Placed",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "✅ Food Preparing",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "🔥 Out For Delivery",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "⏳ Delivered",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ETA Card
            Container(
              width: double.infinity,
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
              child: const Column(
                children: [

                  Text(
                    "⏱ Estimated Delivery Time",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "25 Minutes",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call),
                label: const Text(
                  "Call Rider",
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.deepPurple,
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
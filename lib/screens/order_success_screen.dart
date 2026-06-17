import 'package:flutter/material.dart';
import 'order_tracking_screen.dart';
import 'home_screen.dart';
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [

              const Text(
                "🎉",
                style: TextStyle(
                  fontSize: 80,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Order Placed Successfully!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Your food is being prepared 👩‍🍳",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                          12),
                ),
                child: const Text(
                  "Order ID: #JB12345",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          const OrderTrackingScreen(),
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
                    "Track Order",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) =>
          const HomeScreen(),
    ),
    (route) => false,
  );
},
                  child: const Text(
                    "Back to Home",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
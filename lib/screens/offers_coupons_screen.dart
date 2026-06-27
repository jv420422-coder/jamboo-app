import 'package:flutter/material.dart';

class OffersCouponsScreen extends StatelessWidget {
  const OffersCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "🎁 Offers & Coupons",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          couponCard(
            context,
            "JAMBOO50",
            "₹50 OFF on orders above ₹299",
          ),

          couponCard(
            context,
            "FIRSTORDER",
            "Get 20% OFF on your first order",
          ),

          couponCard(
            context,
            "FREEDELIVERY",
            "Free delivery on selected restaurants",
          ),
        ],
      ),
    );
  }

  Widget couponCard(
    BuildContext context,
    String code,
    String description,
  ) {
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

          Text(
            code,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 8),

          Text(description),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {

  Navigator.pop(
    context,
    code,
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
  "Apply",
),
            ),
          ),
        ],
      ),
    );
  }
}
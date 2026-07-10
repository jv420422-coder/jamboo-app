import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "❓ Frequently Asked Questions",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          FAQTile(
            question: "How do I cancel my order?",
            answer:
                "You can cancel your order within the allowed cancellation time from the Order Details screen.",
          ),
          FAQTile(
            question: "How can I track my order?",
            answer:
                "Go to My Orders and open your order to see the live order status.",
          ),
          FAQTile(
            question: "How do I apply a coupon?",
            answer:
                "Apply a valid coupon from the Cart screen before proceeding to payment.",
          ),
          FAQTile(
            question: "What if my payment fails?",
            answer:
                "If your payment fails, you can retry the payment or choose Cash on Delivery if available.",
          ),
          FAQTile(
            question: "How do refunds work?",
            answer:
                "Eligible refunds are processed to the original payment method according to our refund policy.",
          ),
          FAQTile(
            question: "How can I change my delivery address?",
            answer:
                "Before placing your order, go to Saved Addresses and select or add another address.",
          ),
          FAQTile(
            question: "How do I contact support?",
            answer:
                "You can use Call Support or WhatsApp Support from the Help Center.",
          ),
          FAQTile(
            question: "How can I rate a restaurant?",
            answer:
                "After your order is delivered, the Rate Restaurant button will appear in Order Details.",
          ),
        ],
      ),
    );
  }
}

class FAQTile extends StatelessWidget {
  final String question;
  final String answer;

  const FAQTile({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class FeedbackThankYouCard extends StatelessWidget {
  final int rating;

  const FeedbackThankYouCard({
    super.key,
    required this.rating,
  });

  String get title {
    return "Thank You!";
  }

  String get message {
    switch (rating) {
      case 5:
        return "We're delighted that you loved your meal! 🎉";

      case 4:
        return "Thanks! We're glad you enjoyed it. 😊";

      case 3:
        return "Thanks for your feedback. We'll keep improving. 💜";

      case 2:
        return "We're sorry your experience wasn't great. We'll do better.";

      case 1:
        return "We sincerely apologize. Your feedback will help us improve.";

      default:
        return "Thank you for your valuable feedback.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FFF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD6F1DE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD6F1DE),
              ),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.green,
              size: 25,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Thank You!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16803C),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFF4B400),
                  size: 23,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF242424),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Your valuable feedback has been submitted successfully.\n"
            "Your review helps other customers and helps the restaurant improve.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFDDEFE2),
          ),

          const SizedBox(height: 13),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.verified_rounded,
                color: Colors.green,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                "Review Submitted",
                style: TextStyle(
                  color: Color(0xFF16803C),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          const Text(
            "We hope to serve you again soon. 💜",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF7E57C2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class FeedbackThankYouCard extends StatelessWidget {
  final int rating;

  const FeedbackThankYouCard({
    super.key,
    required this.rating,
  });

  String get title {
    return "💚 Thank You!";
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

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: const Color(0xFFF1FFF5),

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: Colors.green,
          width: 1.4,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 2,
                ),
                child: Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Your valuable feedback has been submitted successfully.\n\n"
            "Your review helps other customers\n"
            "and helps the restaurant improve.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          Divider(
            color: Colors.green.shade200,
            thickness: 1,
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: const [

              Icon(
                Icons.verified_rounded,
                color: Colors.green,
                size: 22,
              ),

              SizedBox(width: 8),

              Text(
                "Review Submitted",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

            ],
          ),

          const SizedBox(height: 14),

          const Text(
            "We hope to serve you again soon. 💜",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
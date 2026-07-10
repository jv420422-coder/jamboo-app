import 'package:flutter/material.dart';
import 'faq_screen.dart';
import 'report_problem_screen.dart';
import 'info_screen.dart';
import '../data/app_information.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "🆘 Help Center",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "How can we help you?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Find answers or contact our support team.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          helpTile(
            context,
            "❓",
            "Frequently Asked Questions",
          ),

          const SizedBox(height: 20),

          const Text(
            "Support",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          helpTile(
            context,
            "📞",
            "Call Support",
          ),

          helpTile(
            context,
            "🟢",
            "WhatsApp Support",
          ),

          helpTile(
            context,
            "🐞",
            "Report a Problem",
          ),

          const SizedBox(height: 20),

          const Text(
            "Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          helpTile(
            context,
            "📄",
            "Terms & Conditions",
          ),

          helpTile(
            context,
            "🔒",
            "Privacy Policy",
          ),

          helpTile(
            context,
            "ℹ️",
            "About Jamboo",
          ),
        ],
      ),
    );
  }

  Widget helpTile(
    BuildContext context,
    String emoji,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Text(
          emoji,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
       onTap: () {
  if (title == "Frequently Asked Questions") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FAQScreen(),
      ),
    );
    return;
  }

  if (title == "Report a Problem") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportProblemScreen(),
      ),
    );
    return;
  }

  if (title == "Terms & Conditions") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InfoScreen(
          title: "Terms & Conditions",
         content: AppInformation.termsAndConditions,
        ),
      ),
    );
    return;
  }

  if (title == "Privacy Policy") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InfoScreen(
          title: "Privacy Policy",
         content: AppInformation.privacyPolicy,
        ),
      ),
    );
    return;
  }

  if (title == "About Jamboo") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InfoScreen(
          title: "About Jamboo",
         content: AppInformation.aboutJamboo,
        ),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("$title - Coming Soon"),
    ),
  );
},
      ),
    );
  }
}
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0FF),
        elevation: 0,
        title: const Text(
          "⚙️ Settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            settingTile(
              "🔔",
              "Notifications",
            ),

            settingTile(
              "🌙",
              "Dark Mode",
            ),

            settingTile(
              "🌐",
              "Language",
            ),

            settingTile(
              "🔒",
              "Privacy Policy",
            ),

            settingTile(
              "📄",
              "Terms & Conditions",
            ),

            settingTile(
              "ℹ️",
              "About Jamboo",
            ),
          ],
        ),
      ),
    );
  }

  Widget settingTile(
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
        title: Text(title),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }
}
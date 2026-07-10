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

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          const Text(
            "Appearance",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          settingsTile(
            context,
            icon: Icons.language,
            title: "Language",
            subtitle: "Coming Soon",
          ),

          settingsTile(
            context,
            icon: Icons.dark_mode,
            title: "Dark Mode",
            subtitle: "Coming Soon",
          ),

          const SizedBox(height: 24),

          const Text(
            "Application",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          settingsTile(
            context,
            icon: Icons.star_rate_rounded,
            title: "Rate Jamboo",
          ),

          settingsTile(
            context,
            icon: Icons.share,
            title: "Share Jamboo",
          ),

          settingsTile(
            context,
            icon: Icons.location_on,
            title: "Location Permission",
          ),

          settingsTile(
            context,
            icon: Icons.info_outline,
            title: "App Version",
            subtitle: "Version 1.0.0 (Build 1)",
            showArrow: false,
          ),
        ],
      ),
    );
  }

  Widget settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade50,
          child: Icon(
            icon,
            color: Colors.deepPurple,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              )
            : null,
        trailing: showArrow
            ? const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              )
            : null,
        onTap: () {
          if (title == "App Version") return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title feature coming soon"),
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Replace this with your actual Google Play Store listing URL.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.jamboofooddelivery.app';

  Future<void> _rateJamboo(BuildContext context) async {
    final Uri uri = Uri.parse(playStoreUrl);

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open Google Play Store.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Play Store.'),
        ),
      );
    }
  }

  Future<void> _showLocationPermission(
    BuildContext context,
  ) async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    final permission = await Geolocator.checkPermission();

    if (!context.mounted) return;

    String status;

    if (!serviceEnabled) {
      status = 'Your device location service is turned off.';
    } else if (permission == LocationPermission.deniedForever) {
      status =
          'Location permission is permanently denied. '
          'Please enable it in App Settings.';
    } else if (permission == LocationPermission.denied) {
      status = 'Location permission has not been granted yet.';
    } else {
      status = 'Location permission is enabled.';
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.deepPurple,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text('Location Permission'),
              ),
            ],
          ),
          content: Text(status),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            if (!serviceEnabled)
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Enable Location'),
              )
            else if (permission ==
                LocationPermission.deniedForever)
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await Geolocator.openAppSettings();
                },
                child: const Text('App Settings'),
              )
            else if (permission ==
                LocationPermission.denied)
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  final newPermission =
                      await Geolocator.requestPermission();

                  if (!context.mounted) return;

                  String message;

                  if (newPermission ==
                          LocationPermission.deniedForever ||
                      newPermission ==
                          LocationPermission.denied) {
                    message =
                        'Location permission was not granted.';
                  } else {
                    message =
                        'Location permission has been updated.';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                },
                child: const Text('Allow Permission'),
              ),
          ],
        );
      },
    );
  }

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
            onTap: () => _rateJamboo(context),
          ),

          // Share Jamboo removed.

          settingsTile(
            context,
            icon: Icons.location_on,
            title: "Location Permission",
            onTap: () => _showLocationPermission(context),
          ),

          settingsTile(
            context,
            icon: Icons.info_outline,
            title: "App Version",
            subtitle: "Version 1.0.1",
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
    VoidCallback? onTap,
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
        onTap: onTap ??
            () {
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
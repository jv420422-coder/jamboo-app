import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_wrapper.dart';
import '../screens/onboarding_screen.dart';

class SplashController {
  SplashController._();

  static Future<void> initialize(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();

    final onboardingCompleted =
        prefs.getBool("onboarding_completed") ?? false;

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => onboardingCompleted
            ? const AuthWrapper()
            : const OnboardingScreen(),
      ),
    );
  }
}
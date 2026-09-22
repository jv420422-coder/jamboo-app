import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_information.dart';
import '../models/customer_care_settings_model.dart';
import '../services/customer_care_settings_service.dart';
import 'faq_screen.dart';
import 'info_screen.dart';
import 'report_problem_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() =>
      _HelpCenterScreenState();
}

class _HelpCenterScreenState
    extends State<HelpCenterScreen> {
  final CustomerCareSettingsService _service =
      CustomerCareSettingsService.instance;

  CustomerCareSettingsModel _settings =
      const CustomerCareSettingsModel();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerCareSettings();
  }

  Future<void> _loadCustomerCareSettings() async {
    try {
      final settings = await _service.getSettings();

      if (!mounted) return;

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _callSupport() async {
    final phone = _settings.phoneNumber.trim();

    if (phone.isEmpty) {
      _showMessage(
        'Customer care phone number is not available.',
      );
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        _showMessage(
          'Unable to open the phone app.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to open the phone app.',
        );
      }
    }
  }

  Future<void> _emailSupport() async {
    final email = _settings.email.trim();

    if (email.isEmpty) {
      _showMessage(
        'Customer care email is not available.',
      );
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Jamboo Customer Support',
      },
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        _showMessage(
          'Unable to open the email app.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to open the email app.',
        );
      }
    }
  }

  Future<void> _whatsappSupport() async {
    final whatsappNumber =
    _settings.whatsappNumber.trim();

    if (whatsappNumber.isEmpty) {
      _showMessage(
        'Customer care WhatsApp number is not available.',
      );
      return;
    }

    final cleanedNumber =
        whatsappNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cleanedNumber.isEmpty) {
      _showMessage(
        'Customer care WhatsApp number is not valid.',
      );
      return;
    }

    final uri = Uri.parse(
      'https://wa.me/$cleanedNumber',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(
          'Unable to open WhatsApp.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to open WhatsApp.',
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
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
          if (_isLoading)
            Container(
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading support options...',
                  ),
                ],
              ),
            )
          else ...[
            if (_settings.callEnabled)
              helpTile(
                context,
                "📞",
                "Call Support",
              ),
            if (_settings.emailEnabled)
              helpTile(
                context,
                "📧",
                "Email Support",
              ),
            if (_settings.whatsappEnabled)
              helpTile(
                context,
                "🟢",
                "WhatsApp Support",
              ),
          ],
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
        borderRadius:
            BorderRadius.circular(16),
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

          if (title == "Call Support") {
            _callSupport();
            return;
          }

          if (title == "Email Support") {
            _emailSupport();
            return;
          }

          if (title == "WhatsApp Support") {
            _whatsappSupport();
            return;
          }

          if (title == "Report a Problem") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const ReportProblemScreen(),
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
                  content:
                      AppInformation.termsAndConditions,
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
                  content:
                      AppInformation.privacyPolicy,
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
                  content:
                      AppInformation.aboutJamboo,
                ),
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "$title - Coming Soon",
              ),
            ),
          );
        },
      ),
    );
  }
}
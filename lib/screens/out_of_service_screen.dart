import 'package:flutter/material.dart';

class OutOfServiceScreen extends StatelessWidget {
  final VoidCallback onChangeLocation;

  const OutOfServiceScreen({
    super.key,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // OUT OF SERVICE ILLUSTRATION
              Image.asset(
                'assets/images/out_of_service.png',
                height: 300,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 220,
                    child: Center(
                      child: Icon(
                        Icons.location_off_rounded,
                        size: 90,
                        color: Color(0xFF7E57C2),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // HEADING
              const Text(
                'Ohhhh, sorry!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 12),

              // DESCRIPTION
              const Text(
                'We are not serving your location yet. '
                'We hope to reach you soon!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 26),

              // CHANGE LOCATION BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onChangeLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E57C2),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Change Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
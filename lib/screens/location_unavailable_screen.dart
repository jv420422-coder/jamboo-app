import 'package:flutter/material.dart';

class LocationUnavailableScreen extends StatelessWidget {
  final VoidCallback onChooseSavedAddress;
  final VoidCallback onTurnOnLocation;

  const LocationUnavailableScreen({
    super.key,
    required this.onChooseSavedAddress,
    required this.onTurnOnLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // LOCATION UNAVAILABLE ILLUSTRATION
              Image.asset(
                'assets/images/location_unavailable.png',
                height: 270,
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

              const SizedBox(height: 20),

              // TITLE
              const Text(
                'Location unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 12),

              // DESCRIPTION
              const Text(
                'Oops! We couldn’t find your location.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Turn on your location or choose a saved '
                'address to discover restaurants near you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 26),

              // CHOOSE SAVED ADDRESS BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onChooseSavedAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E57C2),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
                  ),
                  child: const Text(
                    'Choose Saved Address',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // TURN ON LOCATION BUTTON
              TextButton(
                onPressed: onTurnOnLocation,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7E57C2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Turn On Location',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
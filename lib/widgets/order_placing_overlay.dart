import 'dart:async';

import 'package:flutter/material.dart';

/// A premium loading overlay shown while a customer order is being placed.
///
/// This widget is intentionally kept separate from PaymentScreen so that
/// the order-processing UI can be changed in the future without rewriting
/// the payment/order placement logic.
///
/// Current version:
/// - Uses emojis for the visual indicator.
/// - Automatically changes the status message with time.
/// - Keeps running until PaymentScreen closes the dialog.
///
/// Future:
/// - Emoji can be replaced with a GIF/animated asset.
/// - Lottie animation can also be added here.
/// - The PaymentScreen will not need to be redesigned for those changes.
class OrderPlacingOverlay extends StatefulWidget {
  const OrderPlacingOverlay({
    super.key,
  });

  @override
  State<OrderPlacingOverlay> createState() =>
      _OrderPlacingOverlayState();
}

class _OrderPlacingOverlayState
    extends State<OrderPlacingOverlay> {
  Timer? _messageTimer;

  int _currentStep = 0;

  /// Order placement status messages.
  ///
  /// The timing is controlled separately below so that we can easily
  /// change the messages or timings in the future.
  final List<_OrderStatusStep> _steps = const [
    _OrderStatusStep(
      emoji: '🔄',
      message: 'Confirming your order...',
      duration: Duration(milliseconds: 1500),
    ),
    _OrderStatusStep(
      emoji: '🔐',
      message: 'Securing your order...',
      duration: Duration(milliseconds: 2000),
    ),
    _OrderStatusStep(
      emoji: '🍽️',
      message: 'Confirming with restaurant...',
      duration: Duration(milliseconds: 1500),
    ),
    _OrderStatusStep(
      emoji: '🚀',
      message: 'Getting your order ready...',
      duration: Duration(days: 1),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _startMessageAnimation();
  }

  /// Changes the message automatically while the order is being processed.
  ///
  /// IMPORTANT:
  /// This timer does NOT decide when the order is completed.
  ///
  /// PaymentScreen will close this overlay only after the actual
  /// customerPlaceOrder request succeeds.
  void _startMessageAnimation() {
    _scheduleNextMessage();
  }

  void _scheduleNextMessage() {
    if (_currentStep >= _steps.length - 1) {
      return;
    }

    _messageTimer = Timer(
      _steps[_currentStep].duration,
      () {
        if (!mounted) return;

        setState(() {
          _currentStep++;
        });

        _scheduleNextMessage();
      },
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return PopScope(
      // Prevent the Android back button from closing the overlay.
      canPop: false,

      child: Material(
        color: Colors.black.withValues(alpha: 0.45),

        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 26,
            ),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------------------------------------------------------
                // ORDER ANIMATION / EMOJI
                //
                // Currently using emoji.
                //
                // Future GIF option:
                //
                // Image.asset(
                //   'assets/animations/order_loading.gif',
                //   width: 70,
                //   height: 70,
                // )
                //
                // Only this section needs to change if we want a GIF.
                // ---------------------------------------------------------
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),

                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },

                  child: Text(
                    step.emoji,
                    key: ValueKey(step.emoji),
                    style: const TextStyle(
                      fontSize: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Main heading.
                const Text(
                  'Placing your order',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),

                const SizedBox(height: 10),

                // Live status message.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),

                  child: Text(
                    step.message,
                    key: ValueKey(step.message),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Small loading indicator.
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF7E57C2),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Please wait a moment...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Represents one status message shown during order placement.
class _OrderStatusStep {
  final String emoji;
  final String message;
  final Duration duration;

  const _OrderStatusStep({
    required this.emoji,
    required this.message,
    required this.duration,
  });
}
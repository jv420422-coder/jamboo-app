import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetService {
  InternetService._();

  static final InternetService instance =
      InternetService._();

  final InternetConnection _connection =
      InternetConnection();

  StreamSubscription<InternetStatus>?
      _statusSubscription;

  /// null = internet status abhi check ho raha hai.
  final ValueNotifier<bool?> isOnline =
      ValueNotifier<bool?>(null);

  bool _checking = false;

  Future<void> initialize() async {
    await _statusSubscription?.cancel();

    // Initial check.
    final hasInternet = await _checkInternetWithRetry();

    isOnline.value = hasInternet;

    _statusSubscription =
        _connection.onStatusChange.listen(
      (InternetStatus status) async {
        try {
          if (status == InternetStatus.connected) {
            // Network reconnect hone ke baad
            // thoda wait karke verify karenge.
            await Future.delayed(
              const Duration(seconds: 1),
            );

            final hasInternet =
                await _checkInternetWithRetry();

            if (hasInternet) {
              isOnline.value = true;
            }
          } else {
            // Network disconnected event aane par
            // turant offline screen nahi dikhayenge.
            await Future.delayed(
              const Duration(seconds: 3),
            );

            final hasInternet =
                await _checkInternetWithRetry();

            if (!hasInternet) {
              isOnline.value = false;
            } else {
              isOnline.value = true;
            }
          }
        } catch (e, stackTrace) {
          debugPrint(
            'Internet status check error: $e',
          );

          debugPrint('$stackTrace');
        }
      },
    );
  }

  Future<bool> _checkInternetWithRetry() async {
    // First check
    final firstCheck =
        await _connection.hasInternetAccess;

    if (firstCheck) {
      return true;
    }

    // Temporary network fluctuation ho sakta hai.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    // Second check
    final secondCheck =
        await _connection.hasInternetAccess;

    if (secondCheck) {
      return true;
    }

    // Final check
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final thirdCheck =
        await _connection.hasInternetAccess;

    return thirdCheck;
  }

  Future<bool> checkNow() async {
    if (_checking) {
      return isOnline.value ?? false;
    }

    _checking = true;

    try {
      final hasInternet =
          await _checkInternetWithRetry();

      isOnline.value = hasInternet;

      return hasInternet;
    } catch (e, stackTrace) {
      debugPrint(
        'Manual internet check error: $e',
      );

      debugPrint('$stackTrace');

      isOnline.value = false;

      return false;
    } finally {
      _checking = false;
    }
  }

  bool get hasInternet =>
      isOnline.value ?? false;

  Future<void> dispose() async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    isOnline.dispose();
  }
}
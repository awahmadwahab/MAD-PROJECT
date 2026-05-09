import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;

  const BiometricAuthResult._({
    required this.success,
    this.errorMessage,
  });

  const BiometricAuthResult.success()
      : this._(
          success: true,
          errorMessage: null,
        );

  const BiometricAuthResult.failure(String message)
      : this._(
          success: false,
          errorMessage: message,
        );
}

class BiometricAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<BiometricAuthResult> authenticateStudent() async {
    if (kIsWeb) {
      return const BiometricAuthResult.failure(
        'Biometric verification is only available on mobile devices.',
      );
    }

    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;

      if (!isSupported && !canCheckBiometrics) {
        return const BiometricAuthResult.failure(
          'This device does not support biometric authentication.',
        );
      }

      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return const BiometricAuthResult.failure(
          'No biometric credentials are enrolled. Please add fingerprint or face unlock in device settings.',
        );
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Verify your identity to access CampuScan',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (!didAuthenticate) {
        return const BiometricAuthResult.failure(
          'Biometric verification was cancelled.',
        );
      }

      return const BiometricAuthResult.success();
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return const BiometricAuthResult.failure(
            'Biometric hardware is not available on this device.',
          );
        case auth_error.notEnrolled:
          return const BiometricAuthResult.failure(
            'No biometrics enrolled. Add fingerprint or face unlock first.',
          );
        case auth_error.passcodeNotSet:
          return const BiometricAuthResult.failure(
            'Device lock screen is not configured. Set a passcode/pin first.',
          );
        case auth_error.lockedOut:
          return const BiometricAuthResult.failure(
            'Biometric authentication is temporarily locked. Try again later.',
          );
        case auth_error.permanentlyLockedOut:
          return const BiometricAuthResult.failure(
            'Biometric authentication is locked. Unlock it from device settings.',
          );
        default:
          return BiometricAuthResult.failure(
            e.message ?? 'Biometric verification failed.',
          );
      }
    } catch (_) {
      return const BiometricAuthResult.failure(
        'Unable to complete biometric verification.',
      );
    }
  }
}

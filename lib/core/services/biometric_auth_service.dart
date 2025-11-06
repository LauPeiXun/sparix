import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      if (!Platform.isAndroid) {
        return false; // Only Android is supported
      }

      final bool isAvailable = await _localAuth.isDeviceSupported();
      return isAvailable;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric availability: $e');
      }
      return false;
    }
  }

  Future<bool> isBiometricEnrolled() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }

      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return canCheckBiometrics;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric enrollment: $e');
      }
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (!Platform.isAndroid) {
        return [];
      }

      final List<BiometricType> availableBiometrics =
      await _localAuth.getAvailableBiometrics();
      return availableBiometrics;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available biometrics: $e');
      }
      return [];
    }
  }

  Future<BiometricAuthResult> authenticateWithBiometrics({
    String reason = 'Please authenticate to access Sparix',
  }) async {
    try {
      if (!Platform.isAndroid) {
        return BiometricAuthResult(
          isAuthenticated: false,
          errorMessage: 'Biometric authentication is only supported on Android',
        );
      }

      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          isAuthenticated: false,
          errorMessage: 'Biometric authentication is not available on this device',
        );
      }

      final bool isEnrolled = await isBiometricEnrolled();
      if (!isEnrolled) {
        return BiometricAuthResult(
          isAuthenticated: false,
          errorMessage: 'No biometrics enrolled. Please set up fingerprint or face unlock in your device settings',
        );
      }
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Sparix Authentication',
            biometricHint: 'Touch the fingerprint sensor',
            biometricNotRecognized: 'Biometric not recognized, try again',
            biometricSuccess: 'Biometric authentication successful',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device Credential Required',
            deviceCredentialsSetupDescription: 'Please set up device credentials',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Set up biometric authentication in Settings',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (didAuthenticate) {
        return BiometricAuthResult(
          isAuthenticated: true,
          errorMessage: null,
        );
      } else {
        return BiometricAuthResult(
          isAuthenticated: false,
          errorMessage: 'Authentication cancelled by user',
        );
      }
    } on PlatformException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometric authentication is not available on this device';
          break;
        case 'NotEnrolled':
          errorMessage = 'No biometrics enrolled. Please set up fingerprint or face unlock';
          break;
        case 'LockedOut':
          errorMessage = 'Too many failed attempts. Please try again later';
          break;
        default:
          errorMessage = 'Authentication failed: ${e.message}';
      }

      if (kDebugMode) {
        print('Biometric authentication error: ${e.code} - ${e.message}');
      }

      return BiometricAuthResult(
        isAuthenticated: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected biometric authentication error: $e');
      }
      return BiometricAuthResult(
        isAuthenticated: false,
        errorMessage: 'An unexpected error occurred during authentication',
      );
    }
  }

  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping authentication: $e');
      }
    }
  }

  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.weak:
        return 'Weak Biometric';
      case BiometricType.strong:
        return 'Strong Biometric';
    }
  }

  Future<BiometricType?> getPrimaryBiometricType() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) return null;

    if (biometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    }
    if (biometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    }
    if (biometrics.contains(BiometricType.strong)) {
      return BiometricType.strong;
    }

    return biometrics.first;
  }
}

class BiometricAuthResult {
  final bool isAuthenticated;
  final String? errorMessage;

  BiometricAuthResult({
    required this.isAuthenticated,
    this.errorMessage,
  });

  bool get isSuccess => isAuthenticated;
  bool get isFailure => !isAuthenticated;
  bool get hasError => errorMessage != null;
}
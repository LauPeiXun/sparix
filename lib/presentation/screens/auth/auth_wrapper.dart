import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sparix/core/services/biometric_auth_service.dart';
import 'package:sparix/presentation/screens/auth/biometric_lock_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;
  final bool requireBiometric;

  const AuthWrapper({
    super.key,
    required this.child,
    this.requireBiometric = true,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isCheckingBiometric = true;
  bool _shouldShowBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    if (!widget.requireBiometric || !Platform.isAndroid) {
      setState(() {
        _isCheckingBiometric = false;
        _shouldShowBiometric = false;
      });
      return;
    }

    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnrolled = await _biometricService.isBiometricEnrolled();

      setState(() {
        _isCheckingBiometric = false;
        _shouldShowBiometric = isAvailable && isEnrolled;
      });
    } catch (e) {
      setState(() {
        _isCheckingBiometric = false;
        _shouldShowBiometric = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingBiometric) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ),
      );
    }

    if (_shouldShowBiometric) {
      return BiometricLockScreen(
        nextScreen: widget.child,
        customMessage: 'Please authenticate to access Sparix',
      );
    }

    return widget.child;
  }
}
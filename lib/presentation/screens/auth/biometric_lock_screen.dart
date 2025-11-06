import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sparix/core/services/biometric_auth_service.dart';

class BiometricLockScreen extends StatefulWidget {
  final Widget nextScreen;
  final String? customMessage;

  const BiometricLockScreen({
    super.key,
    required this.nextScreen,
    this.customMessage,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with TickerProviderStateMixin {
  final BiometricAuthService _biometricService = BiometricAuthService();

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isAuthenticating = false;
  String? _errorMessage;
  BiometricType? _primaryBiometricType;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeBiometric();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeBiometric() async {
    if (!Platform.isAndroid) {
      _navigateToNextScreen();
      return;
    }

    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnrolled = await _biometricService.isBiometricEnrolled();

      if (!isAvailable || !isEnrolled) {
        _navigateToNextScreen();
        return;
      }

      _primaryBiometricType = await _biometricService.getPrimaryBiometricType();
      setState(() {});

      // Auto-trigger authentication after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _authenticateWithBiometric();
        }
      });
    } catch (e) {
      _navigateToNextScreen();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final result = await _biometricService.authenticateWithBiometrics(
        reason: widget.customMessage ?? 'Please authenticate to access Sparix',
      );

      if (result.isSuccess) {
        _navigateToNextScreen();
      } else {
        setState(() {
          _errorMessage = result.errorMessage;
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed. Please try again.';
        _isAuthenticating = false;
      });
    }
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => widget.nextScreen),
    );
  }


  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SPARIX Logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/icons/Sparix_logo.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Subtitle
                        const Text(
                          'Spare Parts Management',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),

                        // Error Message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 40),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Section - Fingerprint
              Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Column(
                  children: [
                    // Fingerprint Icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
                          child: GestureDetector(
                            onTap: _isAuthenticating ? null : _authenticateWithBiometric,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade100,
                                border: Border.all(
                                  color: const Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _getBiometricIcon(),
                                size: 40,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Instruction Text
                    Text(
                      _isAuthenticating
                          ? 'Authenticating...'
                          : 'Scan fingerprint',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (_isAuthenticating) ...[
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    switch (_primaryBiometricType) {
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.face:
        return Icons.face;
      case BiometricType.iris:
        return Icons.visibility;
      default:
        return Icons.security;
    }
  }

}
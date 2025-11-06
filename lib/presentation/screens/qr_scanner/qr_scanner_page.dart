import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sparix/presentation/components/app_bar.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/presentation/screens/spare_parts/spare_part_details_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> with WidgetsBindingObserver {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  BarcodeCapture? result;
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isDenied || status.isRestricted) {
      final result = await Permission.camera.request();
      setState(() {
        hasPermission = result.isGranted;
      });
    } else if (status.isGranted) {
      setState(() {
        hasPermission = true;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        hasPermission = false;
      });
    } else {
      // For any other status, try requesting
      final result = await Permission.camera.request();
      setState(() {
        hasPermission = result.isGranted;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!controller.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
      // App is resumed, start the scanner
        controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      // App is paused or inactive, stop the scanner
        controller.stop();
        break;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Don't call start/stop in reassemble for mobile_scanner
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: !hasPermission
          ? _buildPermissionDenied()
          : Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onBarcodeDetected,
            fit: BoxFit.cover,
          ),
          _buildScannerOverlay(),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _toggleFlash,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CE65C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.flashlight_on, size: 24),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      final rawValue = capture.barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        // Stop scanning temporarily (optional, depending on your controller)
        controller.stop();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SparePartDetailsPage(productId: rawValue),
          ),
        ).then((_) {
          setState(() {
            result = null;
          });

          controller.start();
        });
      }
    }
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Camera access is needed to scan QR codes. Please grant permission to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                final status = await Permission.camera.status;
                if (status.isPermanentlyDenied) {
                  await openAppSettings();
                } else {
                  final result = await Permission.camera.request();
                  setState(() {
                    hasPermission = result.isGranted;
                  });
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Allow Camera Access'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ScannerOverlay(
          borderColor: Color(0xFF5CE65C),
          borderWidth: 4.0,
          borderLength: 30.0,
          borderRadius: 12.0,
          cutOutSize: 250.0,
        ),
      ),
    );
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
  }
}

class ScannerOverlay extends CustomPainter {
  const ScannerOverlay({
    required this.borderColor,
    required this.borderWidth,
    required this.borderLength,
    required this.borderRadius,
    required this.cutOutSize,
  });

  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Draw dark overlay with transparent center
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        cutOutRect,
        Radius.circular(borderRadius),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw corner borders
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final cornerOffset = borderWidth / 2;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - cornerOffset, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.left - cornerOffset, cutOutRect.top + borderRadius)
        ..arcToPoint(
          Offset(cutOutRect.left + borderRadius, cutOutRect.top - cornerOffset),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top - cornerOffset),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLength, cutOutRect.top - cornerOffset)
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top - cornerOffset)
        ..arcToPoint(
          Offset(cutOutRect.right + cornerOffset, cutOutRect.top + borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutRect.right + cornerOffset, cutOutRect.top + borderLength),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right + cornerOffset, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.right + cornerOffset, cutOutRect.bottom - borderRadius)
        ..arcToPoint(
          Offset(cutOutRect.right - borderRadius, cutOutRect.bottom + cornerOffset),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + cornerOffset),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom + cornerOffset)
        ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom + cornerOffset)
        ..arcToPoint(
          Offset(cutOutRect.left - cornerOffset, cutOutRect.bottom - borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutRect.left - cornerOffset, cutOutRect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
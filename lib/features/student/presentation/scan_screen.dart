import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/firebase_service.dart';
import 'package:campuscan/core/offline_vault_service.dart';
import 'package:campuscan/core/qr_security_service.dart';

class StudentScanScreen extends StatefulWidget {
  const StudentScanScreen({super.key});

  @override
  State<StudentScanScreen> createState() => _StudentScanScreenState();
}

class _StudentScanScreenState extends State<StudentScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeCapture(BarcodeCapture capture) async {
    if (_scanning) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        await _handleScan(rawValue.trim());
        break;
      }
    }
  }

  Future<void> _handleScan(String payload) async {
    if (_scanning) return;
    final appState = context.read<AppState>();
    final student = appState.currentStudent;
    if (student == null) return;

    setState(() => _scanning = true);

    final result = QrSecurityService.validatePayload(payload);
    if (result['valid'] != true) {
      _goToVerification(
        success: false,
        courseCode: '',
        message: result['error'] as String? ?? 'Invalid QR code',
      );
      return;
    }

    final data = result['data'] as Map<String, dynamic>;
    final sessionId = data['sessionId'] as String? ?? '';
    final courseCode = data['courseCode'] as String? ?? '';
    final teacherId = data['teacherId'] as String?;
    final sessionStatus = await _checkSessionStatus(sessionId);

    if (sessionStatus == _SessionStatus.inactiveOrMissing) {
      _goToVerification(
        success: false,
        courseCode: courseCode,
        message: 'This attendance session is no longer active.',
      );
      return;
    }

    final scannedAt = DateTime.now();
    final rollNo = student['rollNo'] as String? ?? '';
    final studentName = student['name'] as String? ?? 'Student';

    if (sessionStatus == _SessionStatus.unreachable) {
      await OfflineVaultService.saveRecord(
        studentId: rollNo,
        studentName: studentName,
        sessionId: sessionId,
        courseCode: courseCode,
        teacherId: teacherId,
        scannedAt: scannedAt,
      );

      _goToVerification(
        success: true,
        courseCode: courseCode,
        message: 'Verified locally & saved to Offline Vault.',
        savedOffline: true,
      );
      return;
    }

    try {
      await FirebaseService.markPresent(
        rollNo: rollNo,
        studentName: studentName,
        courseCode: courseCode,
        sessionId: sessionId,
        teacherId: teacherId,
        timestamp: scannedAt,
      );

      _goToVerification(
        success: true,
        courseCode: courseCode,
        message: 'Attendance marked successfully.',
        savedOffline: false,
      );
    } catch (_) {
      await OfflineVaultService.saveRecord(
        studentId: rollNo,
        studentName: studentName,
        sessionId: sessionId,
        courseCode: courseCode,
        teacherId: teacherId,
        scannedAt: scannedAt,
      );

      _goToVerification(
        success: true,
        courseCode: courseCode,
        message: 'Saved to Offline Vault.',
        savedOffline: true,
      );
    }
  }

  Future<_SessionStatus> _checkSessionStatus(String sessionId) async {
    try {
      final session = await FirebaseService.getSession(sessionId);
      if (session == null || session['active'] != true) return _SessionStatus.inactiveOrMissing;
      return _SessionStatus.active;
    } catch (_) {
      return _SessionStatus.unreachable;
    }
  }

  void _goToVerification({
    required bool success,
    required String courseCode,
    required String message,
    bool savedOffline = false,
  }) {
    if (!mounted) return;
    context.go(
      '/student/verified',
      extra: {
        'success': success,
        'courseCode': courseCode,
        'message': message,
        'savedOffline': savedOffline,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleBarcodeCapture,
            ),
          ),

          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.white,
                borderRadius: 20,
                borderLength: 30,
                borderWidth: 6,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          ),

          // Header Instruction
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Align QR within frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 10)],
                ),
              ),
            ),
          ),

          // Cancel Button
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () => context.go('/student/home'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.black.withValues(alpha: 0.2),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 10,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final double cutOutWidth = cutOutSize;
    final double cutOutHeight = cutOutSize;
    final double left = (width - cutOutWidth) / 2;
    final double top = (height - cutOutHeight) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromLTWH(left, top, cutOutWidth, cutOutHeight);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius))),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final borderPath = Path();

    // Top Left
    borderPath.moveTo(left, top + borderLength);
    borderPath.lineTo(left, top + borderRadius);
    borderPath.arcToPoint(Offset(left + borderRadius, top), radius: Radius.circular(borderRadius));
    borderPath.lineTo(left + borderLength, top);

    // Top Right
    borderPath.moveTo(left + cutOutWidth - borderLength, top);
    borderPath.lineTo(left + cutOutWidth - borderRadius, top);
    borderPath.arcToPoint(Offset(left + cutOutWidth, top + borderRadius), radius: Radius.circular(borderRadius));
    borderPath.lineTo(left + cutOutWidth, top + borderLength);

    // Bottom Left
    borderPath.moveTo(left, top + cutOutHeight - borderLength);
    borderPath.lineTo(left, top + cutOutHeight - borderRadius);
    borderPath.arcToPoint(Offset(left + borderRadius, top + cutOutHeight), radius: Radius.circular(borderRadius), clockwise: false);
    borderPath.lineTo(left + borderLength, top + cutOutHeight);

    // Bottom Right
    borderPath.moveTo(left + cutOutWidth - borderLength, top + cutOutHeight);
    borderPath.lineTo(left + cutOutWidth - borderRadius, top + cutOutHeight);
    borderPath.arcToPoint(Offset(left + cutOutWidth, top + cutOutHeight - borderRadius), radius: Radius.circular(borderRadius), clockwise: false);
    borderPath.lineTo(left + cutOutWidth, top + cutOutHeight - borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
        borderColor: borderColor,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
        borderLength: borderLength,
        cutOutSize: cutOutSize,
      );
}

enum _SessionStatus { active, inactiveOrMissing, unreachable }

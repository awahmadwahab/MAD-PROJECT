import 'dart:async';

import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/firebase_service.dart';
import 'package:campuscan/core/qr_security_service.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TeacherSessionScreen extends StatefulWidget {
  const TeacherSessionScreen({super.key});

  @override
  State<TeacherSessionScreen> createState() => _TeacherSessionScreenState();
}

class _TeacherSessionScreenState extends State<TeacherSessionScreen> {
  Timer? _qrTimer;
  Timer? _countdownTimer;
  double _progress = 1.0;
  String _currentPayload = '';

  @override
  void initState() {
    super.initState();
    _generateNewQr();
    _startTimers();
  }

  void _startTimers() {
    _qrTimer?.cancel();
    _countdownTimer?.cancel();

    _qrTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _generateNewQr();
      if (mounted) {
        setState(() {
          _progress = 1.0;
        });
      }
    });

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _progress -= 0.1 / 10;
          if (_progress < 0) _progress = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _generateNewQr() {
    final appState = context.read<AppState>();
    final sessionId = appState.activeSessionId;
    final courseCode = appState.activeCourseCode;
    final teacherId = appState.currentTeacher?['id'] as String?;

    if (sessionId == null || courseCode == null || teacherId == null) return;

    if (mounted) {
      setState(() {
        _currentPayload = QrSecurityService.generatePayload(
          sessionId: sessionId,
          courseCode: courseCode,
          teacherId: teacherId,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final sessionId = appState.activeSessionId;
    final courseCode = appState.activeCourseCode;
    final isWebLayout = MediaQuery.of(context).size.width >= 1024;

    if (sessionId == null || courseCode == null) {
      return const Scaffold(body: Center(child: Text("No Active Session")));
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.getCourse(courseCode),
      builder: (context, courseSnapshot) {
        final course = courseSnapshot.data ?? <String, dynamic>{};
        final courseTitle = (course['name'] ?? '').toString();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.streamRecordsForSession(sessionId),
          builder: (context, recordSnapshot) {
            final sessionRecords =
                recordSnapshot.data?.docs.map((doc) => doc.data()).toList() ??
                [];

            if (isWebLayout) {
              return _WebLiveProjectorLayout(
                courseCode: courseCode,
                courseTitle: courseTitle,
                payload: _currentPayload,
                progress: _progress,
                sessionRecords: sessionRecords,
                onEndTap: () async {
                  await appState.endSession();
                  if (context.mounted) context.go('/teacher/dashboard');
                },
              );
            }

            return _MobileSessionLayout(
              courseCode: courseCode,
              courseTitle: courseTitle,
              payload: _currentPayload,
              progress: _progress,
              sessionRecords: sessionRecords,
              onEndTap: () async {
                await appState.endSession();
                if (context.mounted) context.go('/teacher/dashboard');
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// WEB PROJECTOR LAYOUT  (split: QR left | list right)
// ─────────────────────────────────────────────
class _WebLiveProjectorLayout extends StatelessWidget {
  final String courseCode;
  final String courseTitle;
  final String payload;
  final double progress;
  final List<Map<String, dynamic>> sessionRecords;
  final VoidCallback onEndTap;

  const _WebLiveProjectorLayout({
    required this.courseCode,
    required this.courseTitle,
    required this.payload,
    required this.progress,
    required this.sessionRecords,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticlesBackground(
        child: Center(
          child: Container(
            width: 1200,
            height: 780,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 100,
                  offset: const Offset(0, 40),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 48, 48, 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$courseCode: $courseTitle',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Scan with the CampuScan Mobile App',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Count pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              color: AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${sessionRecords.length} scanned',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: onEndTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'End Session',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceLight,
                  color: AppColors.primary,
                  minHeight: 2,
                ),

                // ── Body: QR left  |  Attendee list right ───────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Left: QR Code ──────────────────────
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 50,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: payload.isEmpty
                                  ? const SizedBox(
                                      width: 300,
                                      height: 300,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : QrImageView(
                                      data: payload,
                                      version: QrVersions.auto,
                                      size: 300,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 40),

                        // ── Right: Attendee List ───────────────
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.checklist_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Live Attendance',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: sessionRecords.isEmpty
                                    ? _EmptyAttendeeState()
                                    : ListView.separated(
                                        itemCount: sessionRecords.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final record =
                                              sessionRecords[index];
                                          return _AttendeeRow(
                                            record: record,
                                            index: index + 1,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────
// MOBILE SESSION LAYOUT  (QR top | list bottom)
// ─────────────────────────────────────────────
class _MobileSessionLayout extends StatelessWidget {
  final String courseCode;
  final String courseTitle;
  final String payload;
  final double progress;
  final List<Map<String, dynamic>> sessionRecords;
  final VoidCallback onEndTap;

  const _MobileSessionLayout({
    required this.courseCode,
    required this.courseTitle,
    required this.payload,
    required this.progress,
    required this.sessionRecords,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courseCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (courseTitle.isNotEmpty)
                          Text(
                            courseTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onEndTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'End',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.primary,
              minHeight: 2,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: payload.isEmpty
                      ? const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : QrImageView(
                          data: payload,
                          version: QrVersions.auto,
                          size: 200,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1A1A2E),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Count + list header ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sessionRecords.length} student${sessionRecords.length == 1 ? '' : 's'} scanned',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Attendee list ──────────────────────────────────
            Expanded(
              child: sessionRecords.isEmpty
                  ? _EmptyAttendeeState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: sessionRecords.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _AttendeeRow(
                          record: sessionRecords[index],
                          index: index + 1,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED: Single attendee row tile
// ─────────────────────────────────────────────
class _AttendeeRow extends StatelessWidget {
  final Map<String, dynamic> record;
  final int index;

  const _AttendeeRow({required this.record, required this.index});

  String _formatTime(dynamic raw) {
    try {
      DateTime dt;
      if (raw is Timestamp) {
        dt = raw.toDate();
      } else if (raw is String) {
        dt = DateTime.parse(raw).toLocal();
      } else {
        return '--:--';
      }
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (record['studentName'] ?? 'Unknown').toString();
    final rollNo = (record['rollNo'] ?? '').toString();
    final timeStr = _formatTime(record['scannedAt'] ?? record['timestamp']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + Roll
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rollNo,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED: Empty state widget
// ─────────────────────────────────────────────
class _EmptyAttendeeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.textMuted,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Waiting for students to scan...',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

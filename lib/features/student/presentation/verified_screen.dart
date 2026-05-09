import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';

class StudentVerifiedScreen extends StatefulWidget {
  final bool success;
  final String courseCode;
  final String message;
  final bool savedOffline;

  const StudentVerifiedScreen({
    super.key,
    required this.success,
    required this.courseCode,
    required this.message,
    this.savedOffline = false,
  });

  @override
  State<StudentVerifiedScreen> createState() => _StudentVerifiedScreenState();
}

class _StudentVerifiedScreenState extends State<StudentVerifiedScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.success ? AppColors.success : AppColors.error;

    return Scaffold(
      body: ParticlesBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: widget.success
                            ? AppColors.successGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.error,
                                  AppColors.error.withValues(alpha: 0.7)
                                ],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.success
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Status text
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          widget.success
                              ? 'Attendance Confirmed!'
                              : 'Verification Failed',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),

                        if (widget.success) ...[
                          const SizedBox(height: 24),

                          // Course info chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.class_rounded,
                                    color: AppColors.accent, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  widget.courseCode,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sync status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.savedOffline
                                      ? Icons.cloud_off_rounded
                                      : Icons.cloud_done_rounded,
                                  color: widget.savedOffline
                                      ? AppColors.warning
                                      : AppColors.success,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.savedOffline
                                      ? 'Saved to Offline Vault'
                                      : 'Synced to Campus Records',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),

                        GradientButton(
                          label: widget.success ? 'Done' : 'Try Again',
                          icon: widget.success
                              ? Icons.home_rounded
                              : Icons.refresh_rounded,
                          onPressed: () => context.go(
                            widget.success ? '/student/home' : '/student/scan',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

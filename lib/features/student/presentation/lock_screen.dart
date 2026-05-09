import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/biometric_auth_service.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';

class StudentLockScreen extends StatefulWidget {
  const StudentLockScreen({super.key});

  @override
  State<StudentLockScreen> createState() => _StudentLockScreenState();
}

class _StudentLockScreenState extends State<StudentLockScreen> {
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptBiometric();
    });
  }

  Future<void> _promptBiometric() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await BiometricAuthService.authenticateStudent();

    if (!mounted) return;

    if (result.success) {
      context.read<AppState>().unlockApp();
    } else {
      setState(() {
        _error = result.errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = context.read<AppState>().currentStudent?['name'] ?? 'Student';

    return Scaffold(
      body: ParticlesBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: GlassCard(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_person_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back,',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      studentName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: 'Unlock with Fingerprint',
                        icon: Icons.fingerprint_rounded,
                        loading: _isLoading,
                        onPressed: _promptBiometric,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        context.read<AppState>().logout();
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

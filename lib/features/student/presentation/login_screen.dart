import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/biometric_auth_service.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen>
    with SingleTickerProviderStateMixin {
  final _rollNoController = TextEditingController(text: '2021-CS-01');
  final _passwordController = TextEditingController(text: 'student123');
  bool _loginLoading = false;
  String? _error;
  bool _biometricDone = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _rollNoController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loginLoading) return;

    if (!_biometricDone) {
      setState(() => _error = 'Please verify identity with Fingerprint first');
      return;
    }

    setState(() {
      _loginLoading = true;
      _error = null;
    });

    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final appState = context.read<AppState>();
    final result = await appState.loginStudent(_rollNoController.text.trim().toUpperCase());

    if (result.success) {
      if (mounted) context.go('/student/home');
    } else {
      setState(() {
        _error = result.errorMessage ?? 'Roll number not found. Ensure database is seeded.';
        _loginLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticlesBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Added Back button for easier navigation
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GlassCard(
                      width: 380,
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AppColors.successGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          Text('Student Login', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 32),

                          TextField(
                            controller: _rollNoController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Roll Number',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Fingerprint Verification
                          GestureDetector(
                            onTap: () async {
                              final result = await BiometricAuthService.authenticateStudent();
                              if (result.success) {
                                if (mounted) {
                                  setState(() {
                                    _biometricDone = true;
                                    _error = null;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Identity Verified!'), duration: Duration(seconds: 1)),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  setState(() => _error = result.errorMessage);
                                }
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _biometricDone
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _biometricDone ? AppColors.success : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.fingerprint_rounded,
                                    size: 48,
                                    color: _biometricDone ? AppColors.success : AppColors.textMuted
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _biometricDone ? 'Identity Verified' : 'Tap to Scan Fingerprint',
                                    style: TextStyle(
                                      color: _biometricDone ? AppColors.success : AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                            ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              label: _loginLoading ? 'Logging in...' : 'Sign In',
                              icon: Icons.arrow_forward_rounded,
                              loading: _loginLoading,
                              onPressed: _handleLogin,
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: 'ali@campus.edu');
  final _passwordController = TextEditingController(text: '123456');
  bool _loading = false;
  String? _error;
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
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final appState = context.read<AppState>();
    final success = await appState.loginTeacher(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success) {
      if (mounted) context.go('/teacher/dashboard');
    } else {
      setState(() {
        _error = 'Invalid credentials or teacher profile not found';
        _loading = false;
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
                    // Back button (to role selection)
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
                      width: 420,
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Faculty Login',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Access your teaching dashboard',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 32),

                          // Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'University Email',
                              hintText: 'name@campus.edu',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.textMuted,
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 8),

                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: GradientButton(
                              label: 'Launch Dashboard',
                              icon: Icons.login_rounded,
                              onPressed: _handleLogin,
                              loading: _loading,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/offline_vault_service.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final student = appState.currentStudent;
    if (student == null) return const SizedBox.shrink();

    final rollNo = student['rollNo'] as String;
    final name = student['name'] as String;

    return Scaffold(
      body: ParticlesBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _animController,
              curve: Curves.easeOut,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, ${name.split(' ').first}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            rollNo,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/student/profile'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceLight,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.person_rounded, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Offline Vault Banner
                  FutureBuilder<int>(
                    future: OfflineVaultService.getPendingCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          onTap: () => context.go('/student/vault'),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off_rounded, color: AppColors.warning),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Offline Vault', style: TextStyle(fontWeight: FontWeight.w700)),
                                    Text('$count record pending sync', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),

                  // Big Scan QR Button
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/student/scan'),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.textPrimary, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                'SCAN QR',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

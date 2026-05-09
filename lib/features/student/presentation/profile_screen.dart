import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final student = appState.currentStudent;

    return Scaffold(
      body: ParticlesBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        student?['name'] ?? 'Student Name',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        student?['rollNo'] ?? 'Roll Number',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                const Text('Device Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.phonelink_lock_rounded, 'Binding Status', 'Verified'),
                      const Divider(color: AppColors.surfaceLight),
                      _buildInfoRow(Icons.fingerprint_rounded, 'Biometrics', 'Enabled'),
                      const Divider(color: AppColors.surfaceLight),
                      _buildInfoRow(Icons.security_rounded, 'App Version', '1.0.0+1'),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      appState.logout();
                      context.go('/');
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: const Text('Logout Session', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

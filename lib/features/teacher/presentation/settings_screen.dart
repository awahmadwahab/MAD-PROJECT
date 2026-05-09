import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';
import 'package:campuscan/features/teacher/presentation/teacher_wireframe_widgets.dart';

class TeacherSettingsScreen extends StatelessWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final teacher = appState.currentTeacher;
    if (teacher == null) return const SizedBox.shrink();

    final isWebLayout = MediaQuery.of(context).size.width >= 1024;
    final teacherName = (teacher['name'] ?? 'Teacher').toString();
    final teacherEmail = (teacher['email'] ?? '').toString();
    final department = (teacher['department'] ?? 'Faculty').toString();

    Widget content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              color: TeacherWireframePalette.textPrimary,
              fontSize: isWebLayout ? 48 : 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your faculty profile and preferences.',
            style: TextStyle(
              color: TeacherWireframePalette.textMuted,
              fontSize: isWebLayout ? 18 : 14,
            ),
          ),
          const SizedBox(height: 40),

          // Profile Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.person_rounded, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacherName,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            teacherEmail,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              department,
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Text('Account Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),

          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, color: AppColors.accent),
                  title: const Text('Change Password'),
                  subtitle: const Text('Security update recommended every 90 days'),
                  onTap: () {},
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: AppColors.accent),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage attendance alerts'),
                  trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await appState.logout();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Logout Faculty Session', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );

    if (isWebLayout) {
      return Scaffold(
        body: ParticlesBackground(
          child: TeacherBrowserShell(
            url: 'https://teacher.campuscan.edu/settings',
            sideNav: TeacherWebSideNav(
              teacherName: teacherName,
              activeItem: TeacherNavItem.settings,
              onDashboardTap: () => context.go('/teacher/dashboard'),
              onRecordsTap: () => context.go('/teacher/records'),
              onSettingsTap: () => context.go('/teacher/settings'),
              onLogoutTap: () async {
                await appState.logout();
                if (context.mounted) context.go('/');
              },
            ),
            child: content,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TeacherWireframePalette.pageBackground,
      body: ParticlesBackground(
        child: SafeArea(
          child: Column(
            children: [
              const TeacherMobileTopStatus(),
              Expanded(child: Padding(padding: const EdgeInsets.all(20), child: content)),
              TeacherMobileBottomNav(
                activeItem: TeacherNavItem.settings,
                onHomeTap: () => context.go('/teacher/dashboard'),
                onRecordsTap: () => context.go('/teacher/records'),
                onSettingsTap: () => context.go('/teacher/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

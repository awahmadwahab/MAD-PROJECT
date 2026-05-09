import 'package:campuscan/core/theme.dart';
import 'package:flutter/material.dart';

enum TeacherNavItem { dashboard, records, settings }

class TeacherWireframePalette {
  static const Color pageBackground = AppColors.background;
  static const Color panelBackground = AppColors.surface;
  static const Color border = AppColors.primary;
  static const Color borderLight = AppColors.surfaceLight;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color inactiveText = AppColors.textMuted;
  static const Color activeFill = AppColors.primary;
  static const Color buttonFill = AppColors.surfaceLight;
}

class TeacherBrowserShell extends StatelessWidget {
  final String url;
  final Widget sideNav;
  final Widget child;

  const TeacherBrowserShell({
    super.key,
    required this.url,
    required this.sideNav,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TeacherWireframePalette.pageBackground,
      child: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: TeacherWireframePalette.panelBackground,
              border: Border(
                right: BorderSide(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
              ),
            ),
            child: sideNav,
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Header (Optional browser-like bar removed for cleaner look)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: child,
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

class TeacherWebSideNav extends StatelessWidget {
  final String teacherName;
  final TeacherNavItem activeItem;
  final VoidCallback onDashboardTap;
  final VoidCallback onRecordsTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;

  const TeacherWebSideNav({
    super.key,
    required this.teacherName,
    required this.activeItem,
    required this.onDashboardTap,
    required this.onRecordsTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Branding
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'CampuScan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),

        // Profile Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const Text(
                        'Verified Faculty',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Navigation Menu
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SideNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isActive: activeItem == TeacherNavItem.dashboard,
                  onTap: onDashboardTap,
                ),
                const SizedBox(height: 8),
                _SideNavItem(
                  icon: Icons.history_rounded,
                  label: 'Past Records',
                  isActive: activeItem == TeacherNavItem.records,
                  onTap: onRecordsTap,
                ),
                const SizedBox(height: 8),
                _SideNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: activeItem == TeacherNavItem.settings,
                  onTap: onSettingsTap,
                ),
                const Spacer(),
                _SideNavItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isActive: false,
                  onTap: onLogoutTap,
                  isDestructive: true,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : (isActive ? AppColors.primary : AppColors.textSecondary);

    return Material(
      color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              if (isActive)
                const Spacer(),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Mobile specific components
class TeacherMobileTopStatus extends StatelessWidget {
  final String? label;
  const TeacherMobileTopStatus({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'CampuScan Panel',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceLight,
            child: const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}

class TeacherMobileBottomNav extends StatelessWidget {
  final TeacherNavItem activeItem;
  final VoidCallback onHomeTap;
  final VoidCallback onRecordsTap;
  final VoidCallback onSettingsTap;

  const TeacherMobileBottomNav({
    super.key,
    required this.activeItem,
    required this.onHomeTap,
    required this.onRecordsTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MobileIconNav(Icons.dashboard_rounded, 'Home', activeItem == TeacherNavItem.dashboard, onHomeTap),
          _MobileIconNav(Icons.history_rounded, 'Records', activeItem == TeacherNavItem.records, onRecordsTap),
          _MobileIconNav(Icons.settings_rounded, 'Settings', activeItem == TeacherNavItem.settings, onSettingsTap),
        ],
      ),
    );
  }
}

class _MobileIconNav extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileIconNav(this.icon, this.label, this.isActive, this.onTap);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

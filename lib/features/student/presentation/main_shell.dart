import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campuscan/core/theme.dart';

class StudentMainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const StudentMainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(index),
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.cloud_off_outlined),
              selectedIcon: Icon(Icons.cloud_off_rounded, color: AppColors.primary),
              label: 'Vault',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'core/app_state.dart';
import 'features/landing/landing_screen.dart';
import 'features/teacher/presentation/login_screen.dart';
import 'features/teacher/presentation/dashboard_screen.dart';
import 'features/teacher/presentation/session_screen.dart';
import 'features/teacher/presentation/records_screen.dart';
import 'features/teacher/presentation/settings_screen.dart';
import 'features/student/presentation/login_screen.dart';
import 'features/student/presentation/lock_screen.dart';
import 'features/student/presentation/home_screen.dart';
import 'features/student/presentation/scan_screen.dart';
import 'features/student/presentation/verified_screen.dart';
import 'features/student/presentation/vault_screen.dart';
import 'features/student/presentation/profile_screen.dart';
import 'features/student/presentation/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _studentShellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AppState appState) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: appState,
    redirect: (context, state) {
      if (!appState.authInitialized) return null; // Wait for initialization

      final isLoginRoute = state.matchedLocation == '/' ||
                           state.matchedLocation == '/student/login' ||
                           state.matchedLocation == '/teacher/login';

      if (appState.isLoggedIn) {
        if (appState.currentRole == 'student') {
          if (!appState.isUnlocked) {
            if (state.matchedLocation != '/student/lock') return '/student/lock';
            return null;
          } else {
            if (isLoginRoute || state.matchedLocation == '/student/lock') {
              return '/student/home';
            }
          }
        } else if (appState.currentRole == 'teacher') {
          if (isLoginRoute) return '/teacher/dashboard';
        }
      } else {
        // Not logged in
        if (!isLoginRoute && state.matchedLocation != '/student/verified') {
          return '/';
        }
      }
      return null;
    },
    routes: [
    // Landing
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        if (kIsWeb) return const TeacherLoginScreen();
        return const LandingScreen();
      },
    ),

    // Teacher Routes
    GoRoute(
      path: '/teacher/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TeacherLoginScreen(),
    ),
    GoRoute(
      path: '/teacher/dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TeacherDashboardScreen(),
    ),
    GoRoute(
      path: '/teacher/session',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TeacherSessionScreen(),
    ),
    GoRoute(
      path: '/teacher/records',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TeacherRecordsScreen(),
    ),
    GoRoute(
      path: '/teacher/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TeacherSettingsScreen(),
    ),

    // Student Login & Verification (Outside Shell)
    GoRoute(
      path: '/student/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StudentLoginScreen(),
    ),
    GoRoute(
      path: '/student/lock',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StudentLockScreen(),
    ),
    GoRoute(
      path: '/student/verified',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return StudentVerifiedScreen(
          success: extra['success'] ?? false,
          courseCode: extra['courseCode'] ?? '',
          message: extra['message'] ?? 'Unknown result',
          savedOffline: extra['savedOffline'] ?? false,
        );
      },
    ),

    // Student App Shell (Tabs)
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) {
        return StudentMainShell(navigationShell: navigationShell);
      },
      branches: [
        // Home Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/home',
              builder: (context, state) => const StudentHomeScreen(),
            ),
          ],
        ),
        // Scan Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/scan',
              builder: (context, state) => const StudentScanScreen(),
            ),
          ],
        ),
        // Vault Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/vault',
              builder: (context, state) => const StudentVaultScreen(),
            ),
          ],
        ),
        // Profile Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/profile',
              builder: (context, state) => const StudentProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
}

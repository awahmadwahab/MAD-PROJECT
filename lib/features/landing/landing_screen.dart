import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Landing screen — Role selection (Teacher / Student).
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideTeacher;
  late Animation<Offset> _slideStudent;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideTeacher = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    _slideStudent = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _seedDatabase() async {
    setState(() => _isSeeding = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Clear existing student bindings for demo
      final studentsQuery = await firestore.collection('students').get();
      for (var doc in studentsQuery.docs) {
        batch.delete(doc.reference);
      }

      final teachers = [
        {'id': 'T001', 'name': 'Dr. Ali', 'email': 'ali@campus.edu', 'department': 'Computer Science'},
        {'id': 'T002', 'name': 'Prof. Sara', 'email': 'sara@campus.edu', 'department': 'Software Engineering'},
      ];

      final courses = [
        {'code': 'CS-101', 'name': 'Data Structures', 'teacherId': 'T001', 'time': '09:00 AM - 10:30 AM', 'room': 'Room 301', 'days': ['Mon', 'Wed']},
        {'code': 'SE-2200', 'name': 'Software Engineering', 'teacherId': 'T001', 'time': '11:00 AM - 12:30 PM', 'room': 'Room 405', 'days': ['Tue', 'Thu']},
        {'code': 'SE-201', 'name': 'Database Systems', 'teacherId': 'T002', 'time': '02:00 PM - 03:30 PM', 'room': 'Room 202', 'days': ['Mon', 'Wed', 'Fri']},
      ];

      final students = [
        {'rollNo': '2021-CS-01', 'name': 'Ali Raza', 'section': 'A'},
        {'rollNo': '2021-CS-02', 'name': 'Fatima Noor', 'section': 'A'},
        {'rollNo': '2021-CS-03', 'name': 'Ahmed Khan', 'section': 'A'},
      ];

      for (var t in teachers) {
        batch.set(firestore.collection('teachers').doc(t['id'] as String), t);
      }
      for (var c in courses) {
        batch.set(firestore.collection('courses').doc(c['code'] as String), c);
      }
      for (var s in students) {
        batch.set(firestore.collection('students').doc(s['rollNo'] as String), s);
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database reset and seeded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seeding database: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: ParticlesBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo / Title
                    GestureDetector(
                      onLongPress: _isSeeding ? null : _seedDatabase,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: _isSeeding
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isSeeding)
                      const Text("Resetting bindings...", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 12),
                    Text(
                      'CampuScan',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart Attendance System',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 48),

                    // Role cards
                    if (isWide)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SlideTransition(
                            position: _slideTeacher,
                            child: _buildRoleCard(
                              context,
                              icon: Icons.school_rounded,
                              title: 'Teacher Portal',
                              subtitle: 'Manage sessions & attendance',
                              gradient: AppColors.primaryGradient,
                              onTap: () => context.go('/teacher/login'),
                            ),
                          ),
                          const SizedBox(width: 24),
                          SlideTransition(
                            position: _slideStudent,
                            child: _buildRoleCard(
                              context,
                              icon: Icons.person_rounded,
                              title: 'Student App',
                              subtitle: 'Scan QR & mark attendance',
                              gradient: AppColors.successGradient,
                              onTap: () => context.go('/student/login'),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          SlideTransition(
                            position: _slideTeacher,
                            child: _buildRoleCard(
                              context,
                              icon: Icons.school_rounded,
                              title: 'Teacher Portal',
                              subtitle: 'Manage sessions & attendance',
                              gradient: AppColors.primaryGradient,
                              onTap: () => context.go('/teacher/login'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SlideTransition(
                            position: _slideStudent,
                            child: _buildRoleCard(
                              context,
                              icon: Icons.person_rounded,
                              title: 'Student App',
                              subtitle: 'Scan QR & mark attendance',
                              gradient: AppColors.successGradient,
                              onTap: () => context.go('/student/login'),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 40),
                    Text(
                      "Tip: Long-press logo to reset all device bindings",
                      style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 11),
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

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      width: 280,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: TextStyle(
                  color: gradient.colors.first,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: gradient.colors.first,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

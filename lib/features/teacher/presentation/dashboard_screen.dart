import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/firebase_service.dart';
import 'package:campuscan/features/teacher/presentation/teacher_wireframe_widgets.dart';
import 'package:campuscan/shared/widgets.dart';
import 'package:campuscan/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final teacher = appState.currentTeacher;
    if (teacher == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/teacher/login');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isWebLayout = MediaQuery.of(context).size.width >= 1024;
    final teacherName = (teacher['name'] ?? 'Teacher').toString();
    final teacherId = (teacher['id'] ?? '').toString();

    if (isWebLayout) {
      return Scaffold(
        body: ParticlesBackground(
          child: TeacherBrowserShell(
            url: 'https://teacher.campuscan.edu/dashboard',
            sideNav: TeacherWebSideNav(
              teacherName: teacherName,
              activeItem: TeacherNavItem.dashboard,
              onDashboardTap: () => context.go('/teacher/dashboard'),
              onRecordsTap: () => context.go('/teacher/records'),
              onSettingsTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings will be available soon.'),
                  ),
                );
              },
              onLogoutTap: () async {
                await appState.logout();
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
            child: _TeacherDashboardContent(
              teacherId: teacherId,
              teacherName: teacherName,
              isWeb: true,
            ),
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
              Expanded(
                child: _TeacherDashboardContent(
                  teacherId: teacherId,
                  teacherName: teacherName,
                  isWeb: false,
                ),
              ),
              TeacherMobileBottomNav(
                activeItem: TeacherNavItem.dashboard,
                onHomeTap: () => context.go('/teacher/dashboard'),
                onRecordsTap: () => context.go('/teacher/records'),
                onSettingsTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings will be available soon.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherDashboardContent extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final bool isWeb;

  const _TeacherDashboardContent({
    required this.teacherId,
    required this.teacherName,
    required this.isWeb,
  });

  @override
  State<_TeacherDashboardContent> createState() =>
      _TeacherDashboardContentState();
}

class _TeacherDashboardContentState extends State<_TeacherDashboardContent> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = FirebaseService.getCoursesForTeacher(widget.teacherId);
  }

  void _reloadCourses() {
    if (!mounted) {
      return;
    }

    setState(() {
      _coursesFuture = FirebaseService.getCoursesForTeacher(widget.teacherId);
    });
  }

  Future<void> _showCreateCourseDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCourseSheet(
        teacherId: widget.teacherId,
        onSaved: _reloadCourses,
      ),
    );
  }

  Future<void> _showManageStudentsDialog(
    BuildContext context,
    Map<String, dynamic> course,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManageStudentsSheet(
        course: course,
        onChanged: _reloadCourses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final courses = snapshot.data ?? const <Map<String, dynamic>>[];
        final courseCount = courses.length;
        final content = courses.isEmpty
            ? const _EmptyCourses()
            : widget.isWeb
            ? _WebScheduleGrid(
                courses: courses,
                onManageStudents: (course) =>
                    _showManageStudentsDialog(context, course),
              )
            : _MobileScheduleList(
                courses: courses,
                onManageStudents: (course) =>
                    _showManageStudentsDialog(context, course),
              );

        if (widget.isWeb) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${widget.teacherName}',
                            style: const TextStyle(
                              color: TeacherWireframePalette.textPrimary,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select a course to start generating dynamic QR attendance.',
                            style: TextStyle(
                              color: TeacherWireframePalette.textMuted,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GradientButton(
                          label: 'Add Course',
                          icon: Icons.add_rounded,
                          width: 170,
                          onPressed: () => _showCreateCourseDialog(context),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$courseCount course${courseCount == 1 ? '' : 's'} connected to Firebase',
                          style: const TextStyle(
                            color: TeacherWireframePalette.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Today's Schedule",
                        style: TextStyle(
                          color: TeacherWireframePalette.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$courseCount total',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                content,
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.teacherName,
                            style: const TextStyle(
                              color: TeacherWireframePalette.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Faculty Panel',
                            style: TextStyle(
                              color: TeacherWireframePalette.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceLight,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientButton(
                      label: 'Add Course',
                      icon: Icons.add_rounded,
                      width: 140,
                      onPressed: () => _showCreateCourseDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Today's Schedule",
                  style: TextStyle(
                    color: TeacherWireframePalette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              content,
              if (appState.sessionActive && appState.activeCourseCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: InkWell(
                    onTap: () => context.go('/teacher/session'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sensors_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Live session active: ${appState.activeCourseCode}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WebScheduleGrid extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final ValueChanged<Map<String, dynamic>> onManageStudents;

  const _WebScheduleGrid({
    required this.courses,
    required this.onManageStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: courses
          .map(
            (course) => _ScheduleCard(
              course: course,
              isWeb: true,
              onManageStudents: onManageStudents,
            ),
          )
          .toList(),
    );
  }
}

class _MobileScheduleList extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final ValueChanged<Map<String, dynamic>> onManageStudents;

  const _MobileScheduleList({
    required this.courses,
    required this.onManageStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: courses
          .map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScheduleCard(
                course: course,
                isWeb: false,
                onManageStudents: onManageStudents,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isWeb;
  final ValueChanged<Map<String, dynamic>> onManageStudents;

  const _ScheduleCard({
    required this.course,
    required this.isWeb,
    required this.onManageStudents,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final courseCode = (course['code'] ?? '').toString();
    final isCurrentSession = appState.activeCourseCode == courseCode;
    final hasAnotherSession = appState.sessionActive && !isCurrentSession;
    final cardDisabled = hasAnotherSession;
    final buttonLabel = isCurrentSession ? 'Open Session' : 'Start Session';
    final enrolledCount =
        ((course['studentRollNos'] as List?) ?? const []).length;

    return Opacity(
      opacity: cardDisabled ? 0.5 : 1,
      child: GlassCard(
        width: isWeb ? 420 : double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    courseCode,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isCurrentSession)
                  const Icon(
                    Icons.sensors_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              course['name'].toString(),
              style: TextStyle(
                color: TeacherWireframePalette.textPrimary,
                fontSize: isWeb ? 22 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$enrolledCount student${enrolledCount == 1 ? '' : 's'} enrolled',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  course['time'].toString(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.room_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  course['room'].toString(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: buttonLabel,
                      icon: isCurrentSession
                          ? Icons.arrow_forward_rounded
                          : Icons.play_arrow_rounded,
                      onPressed: cardDisabled
                          ? () {}
                          : () async {
                              if (isCurrentSession) {
                                context.go('/teacher/session');
                                return;
                              }
                              final started = await context
                                  .read<AppState>()
                                  .startSession(courseCode);
                              if (started && context.mounted) {
                                context.go('/teacher/session');
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onManageStudents(course),
                icon: const Icon(Icons.people_alt_rounded),
                label: const Text('Manage Students'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Text(
          'No courses available for this teacher account.',
          style: TextStyle(
            color: TeacherWireframePalette.textMuted,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CREATE COURSE  –  Premium modal bottom sheet
// ═══════════════════════════════════════════════════════════
class _CreateCourseSheet extends StatefulWidget {
  final String teacherId;
  final VoidCallback onSaved;

  const _CreateCourseSheet({required this.teacherId, required this.onSaved});

  @override
  State<_CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends State<_CreateCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  bool _isSaving = false;

  static const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final Set<String> _selectedDays = {};

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSaving) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class day.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseService.createCourse(
        code: _codeCtrl.text.trim().toUpperCase(),
        name: _nameCtrl.text.trim(),
        teacherId: widget.teacherId,
        time: _timeCtrl.text.trim(),
        room: _roomCtrl.text.trim(),
        days: _allDays.where((d) => _selectedDays.contains(d)).toList(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Course created successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Course',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  Text('Fill in the details to register a course',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Form
          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _FormField(
                        controller: _codeCtrl,
                        label: 'Course Code',
                        hint: 'CS-401',
                        icon: Icons.tag_rounded,
                        caps: TextCapitalization.characters,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: _FormField(
                        controller: _nameCtrl,
                        label: 'Course Name',
                        hint: 'Computer Networks',
                        icon: Icons.book_rounded,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        controller: _timeCtrl,
                        label: 'Class Time',
                        hint: '09:00 AM – 10:30 AM',
                        icon: Icons.schedule_rounded,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FormField(
                        controller: _roomCtrl,
                        label: 'Room / Venue',
                        hint: 'Room 301',
                        icon: Icons.room_rounded,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Day chip toggles
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Class Days',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _allDays.map((day) {
                    final selected = _selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () => setState(() {
                        selected
                            ? _selectedDays.remove(day)
                            : _selectedDays.add(day);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.primaryGradient : null,
                          color: selected ? null : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Create Course',
                    icon: Icons.add_circle_rounded,
                    loading: _isSaving,
                    onPressed: _submit,
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

// ═══════════════════════════════════════════════════════════
//  MANAGE STUDENTS  –  Premium modal bottom sheet
// ═══════════════════════════════════════════════════════════
class _ManageStudentsSheet extends StatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback onChanged;

  const _ManageStudentsSheet(
      {required this.course, required this.onChanged});

  @override
  State<_ManageStudentsSheet> createState() => _ManageStudentsSheetState();
}

class _ManageStudentsSheetState extends State<_ManageStudentsSheet> {
  late final String courseCode;
  late final Set<String> enrolledRollNos;
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    courseCode = (widget.course['code'] ?? '').toString();
    enrolledRollNos =
        ((widget.course['studentRollNos'] as List?) ?? const [])
            .map((v) => v.toString().trim().toUpperCase())
            .where((v) => v.isNotEmpty)
            .toSet();
    _studentsFuture = FirebaseService.getAllStudents();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addStudent(Map<String, dynamic> student) async {
    final rollNo = (student['rollNo'] ?? '').toString();
    if (rollNo.isEmpty) return;
    try {
      await FirebaseService.addStudentToCourse(
        courseCode: courseCode,
        studentRollNo: rollNo,
      );
      setState(() => enrolledRollNos.add(rollNo.toUpperCase()));
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ $rollNo added to $courseCode')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _studentsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? [];
              final enrolled = all
                  .where((s) => enrolledRollNos
                      .contains((s['rollNo'] ?? '').toString().toUpperCase()))
                  .toList();
              final q = _query.toLowerCase();
              final available = all
                  .where((s) {
                    final rn = (s['rollNo'] ?? '').toString().toUpperCase();
                    if (enrolledRollNos.contains(rn)) return false;
                    if (q.isEmpty) return true;
                    return rn.toLowerCase().contains(q) ||
                        (s['name'] ?? '').toString().toLowerCase().contains(q);
                  })
                  .toList();

              return Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.successGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.people_alt_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Manage Students · $courseCode',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                              Text(
                                  '${enrolled.length} enrolled · ${available.length} available',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Enrolled chips
                  if (enrolled.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: enrolled.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.success, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${s['rollNo']} · ${s['name']}',
                                    style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by name or roll no…',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textMuted),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppColors.textMuted),
                                onPressed: () => _searchCtrl.clear(),
                              )
                            : null,
                      ),
                    ),
                  ),
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(children: [
                      const Icon(Icons.person_add_rounded,
                          size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text('Available Students (${available.length})',
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  // List
                  Expanded(
                    child: available.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.group_off_rounded,
                                    color: AppColors.textMuted, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  _query.isEmpty
                                      ? 'All students are already enrolled.'
                                      : 'No results for "$_query"',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: available.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final s = available[i];
                              final rollNo =
                                  (s['rollNo'] ?? '').toString();
                              final name = (s['name'] ?? '').toString();
                              final section =
                                  (s['section'] ?? '').toString();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(
                                                  color:
                                                      AppColors.textPrimary,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 14)),
                                          Text(
                                            rollNo +
                                                (section.isNotEmpty
                                                    ? ' · Sec $section'
                                                    : ''),
                                            style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GradientButton(
                                      label: 'Enroll',
                                      icon: Icons.person_add_alt_1_rounded,
                                      width: 110,
                                      onPressed: () => _addStudent(s),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Shared reusable form field widget
// ═══════════════════════════════════════════════════════════
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextCapitalization caps;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.caps = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: caps,
      style: const TextStyle(color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      ),
    );
  }
}


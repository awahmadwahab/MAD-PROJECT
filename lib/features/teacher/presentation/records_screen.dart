import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/csv_download_service.dart';
import 'package:campuscan/core/firebase_service.dart';
import 'package:campuscan/features/teacher/presentation/teacher_wireframe_widgets.dart';
import 'package:campuscan/shared/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TeacherRecordsScreen extends StatefulWidget {
  const TeacherRecordsScreen({super.key});

  @override
  State<TeacherRecordsScreen> createState() => _TeacherRecordsScreenState();
}

class _TeacherRecordsScreenState extends State<TeacherRecordsScreen> {
  String? _selectedCourse;
  Map<String, dynamic>? _latestMasterData;

  void _exportCsv() {
    final masterData = _latestMasterData;
    if (masterData == null || _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance data available to export.')),
      );
      return;
    }

    final dates = (masterData['dates'] as List).cast<String>();
    final rows = (masterData['rows'] as List)
        .map((row) => (row as Map).cast<String, dynamic>())
        .toList();

    final header = ['Roll Number', 'Student Name', ...dates];
    final csvRows = <List<String>>[header];
    for (final row in rows) {
      csvRows.add([
        row['rollNo']?.toString() ?? '',
        row['name']?.toString() ?? '',
        ...dates.map((date) => row[date]?.toString() ?? 'A'),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvRows);
    final dateLabel = DateTime.now().toIso8601String().split('T').first;
    final filename = '${_selectedCourse}_attendance_$dateLabel.csv';
    final didStartDownload = CsvDownloadService.downloadCsv(
      csvContent: csvString,
      filename: filename,
    );

    final message = didStartDownload
        ? 'CSV download started: $filename'
        : 'CSV export is supported on the web teacher portal.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, dynamic> _buildMasterSheet({
    required String courseCode,
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> records,
  }) {
    final dates = records
        .map((r) => r['date'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final rows = students.map((student) {
      final rollNo = (student['rollNo'] ?? '').toString();
      final row = <String, dynamic>{
        'rollNo': rollNo,
        'name': (student['name'] ?? '').toString(),
      };
      for (final date in dates) {
        final present = records.any(
          (record) => record['rollNo'] == rollNo && record['date'] == date,
        );
        row[date] = present ? 'P' : 'A';
      }
      return row;
    }).toList();

    return {
      'courseCode': courseCode,
      'dates': dates,
      'rows': rows,
    };
  }

  List<Map<String, dynamic>> _filterStudentsForCourse({
    required List<Map<String, dynamic>> students,
    required Map<String, dynamic> courseMeta,
  }) {
    final rawStudentRollNos = courseMeta['studentRollNos'];
    final enrolledRollNos = ((rawStudentRollNos is List)
            ? rawStudentRollNos
            : const <dynamic>[])
        .map((rollNo) => rollNo.toString().trim().toUpperCase())
        .where((rollNo) => rollNo.isNotEmpty)
        .toSet();

    if (enrolledRollNos.isNotEmpty) {
      return students.where((student) {
        final rollNo = (student['rollNo'] ?? '').toString().toUpperCase();
        return enrolledRollNos.contains(rollNo);
      }).toList();
    }

    final rawSections = courseMeta['sections'];
    final sections = ((rawSections is List) ? rawSections : const <dynamic>[])
        .map((section) => section.toString().trim().toUpperCase())
        .where((section) => section.isNotEmpty)
        .toSet();
    if (sections.isNotEmpty) {
      return students.where((student) {
        final section = (student['section'] ?? '').toString().toUpperCase();
        return sections.contains(section);
      }).toList();
    }

    final singleSection = (courseMeta['section'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    if (singleSection.isNotEmpty) {
      return students.where((student) {
        final section = (student['section'] ?? '').toString().toUpperCase();
        return section == singleSection;
      }).toList();
    }

    return students;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final teacher = appState.currentTeacher;
    final teacherId = teacher?['id'] as String?;
    final teacherName = (teacher?['name'] ?? 'Teacher').toString();
    final isWebLayout = MediaQuery.of(context).size.width >= 1024;

    if (teacherId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/teacher/login');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final recordsContent = _RecordsBody(
      selectedCourse: _selectedCourse,
      onCourseChanged: (value) => setState(() => _selectedCourse = value),
      onMasterDataChanged: (data) => _latestMasterData = data,
      onExportCsv: _exportCsv,
      buildMasterSheet: _buildMasterSheet,
      filterStudentsForCourse: _filterStudentsForCourse,
    );

    if (isWebLayout) {
      return Scaffold(
        body: ParticlesBackground(
          child: TeacherBrowserShell(
            url:
                'https://teacher.campuscan.edu/records/${_selectedCourse ?? 'cs-101'}',
            sideNav: TeacherWebSideNav(
              teacherName: teacherName,
              activeItem: TeacherNavItem.records,
              onDashboardTap: () => context.go('/teacher/dashboard'),
              onRecordsTap: () => context.go('/teacher/records'),
              onSettingsTap: () => context.go('/teacher/settings'),
              onLogoutTap: () async {
                await appState.logout();
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
            child: recordsContent,
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
              Expanded(child: recordsContent),
              TeacherMobileBottomNav(
                activeItem: TeacherNavItem.records,
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

typedef _BuildMasterSheet = Map<String, dynamic> Function({
  required String courseCode,
  required List<Map<String, dynamic>> students,
  required List<Map<String, dynamic>> records,
});

typedef _FilterStudents = List<Map<String, dynamic>> Function({
  required List<Map<String, dynamic>> students,
  required Map<String, dynamic> courseMeta,
});

class _RecordsBody extends StatelessWidget {
  final String? selectedCourse;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<Map<String, dynamic>> onMasterDataChanged;
  final VoidCallback onExportCsv;
  final _BuildMasterSheet buildMasterSheet;
  final _FilterStudents filterStudentsForCourse;

  const _RecordsBody({
    required this.selectedCourse,
    required this.onCourseChanged,
    required this.onMasterDataChanged,
    required this.onExportCsv,
    required this.buildMasterSheet,
    required this.filterStudentsForCourse,
  });

  @override
  Widget build(BuildContext context) {
    final teacherId = context.read<AppState>().currentTeacher?['id'] as String?;
    final isWebLayout = MediaQuery.of(context).size.width >= 1024;
    if (teacherId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseService.getCoursesForTeacher(teacherId),
      builder: (context, coursesSnapshot) {
        if (coursesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final courses = coursesSnapshot.data ?? const <Map<String, dynamic>>[];
        if (courses.isEmpty) {
          return const _EmptyRecordsState(
            message: 'No courses available for this teacher account.',
          );
        }

        final selected = selectedCourse ?? courses.first['code'] as String?;
        if (selected != selectedCourse) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onCourseChanged(selected);
          });
        }

        final selectedCourseMeta = courses.firstWhere(
          (course) => course['code'] == selected,
          orElse: () => <String, dynamic>{},
        );

        final courseLabel = '$selected Attendance Records';
        final recordsArea = _LiveMasterTable(
          courseCode: selected ?? '',
          courseMeta: selectedCourseMeta,
          onMasterDataChanged: onMasterDataChanged,
          buildMasterSheet: buildMasterSheet,
          filterStudentsForCourse: filterStudentsForCourse,
        );

        if (isWebLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      courseLabel,
                      style: const TextStyle(
                        color: TeacherWireframePalette.textPrimary,
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _DownloadButton(onTap: () {
                    onExportCsv();
                  }),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Course:',
                    style: TextStyle(
                      color: TeacherWireframePalette.textMuted,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CourseDropdown(
                    courses: courses,
                    selectedCourse: selected,
                    onChanged: onCourseChanged,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: recordsArea),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selected ?? ''} Records',
                style: const TextStyle(
                  color: TeacherWireframePalette.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _CourseDropdown(
                courses: courses,
                selectedCourse: selected,
                onChanged: onCourseChanged,
                compact: false,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 360,
                child: recordsArea,
              ),
              const SizedBox(height: 14),
              _DownloadButton(onTap: () {
                onExportCsv();
              }),
            ],
          ),
        );
      },
    );
  }
}

class _LiveMasterTable extends StatelessWidget {
  final String courseCode;
  final Map<String, dynamic> courseMeta;
  final ValueChanged<Map<String, dynamic>> onMasterDataChanged;
  final _BuildMasterSheet buildMasterSheet;
  final _FilterStudents filterStudentsForCourse;

  const _LiveMasterTable({
    required this.courseCode,
    required this.courseMeta,
    required this.onMasterDataChanged,
    required this.buildMasterSheet,
    required this.filterStudentsForCourse,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseService.getAllStudents(),
      builder: (context, studentsSnapshot) {
        if (studentsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = studentsSnapshot.data ?? const <Map<String, dynamic>>[];
        final filteredStudents = filterStudentsForCourse(
          students: students,
          courseMeta: courseMeta,
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.streamRecordsForCourse(courseCode),
          builder: (context, recordsSnapshot) {
            if (recordsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final records =
                recordsSnapshot.data?.docs.map((doc) => doc.data()).toList() ??
                    const <Map<String, dynamic>>[];

            final masterData = buildMasterSheet(
              courseCode: courseCode,
              students: filteredStudents,
              records: records,
            );
            onMasterDataChanged(masterData);
            return _MasterTable(masterData: masterData);
          },
        );
      },
    );
  }
}

class _MasterTable extends StatelessWidget {
  final Map<String, dynamic> masterData;

  const _MasterTable({required this.masterData});

  @override
  Widget build(BuildContext context) {
    final dates = (masterData['dates'] as List).cast<String>();
    final rows = (masterData['rows'] as List)
        .map((row) => (row as Map).cast<String, dynamic>())
        .toList();

    if (rows.isEmpty) {
      return const _EmptyRecordsState(
        message: 'No students mapped to this course yet.',
      );
    }

    if (dates.isEmpty) {
      return const _EmptyRecordsState(
        message: 'No attendance records yet.',
        subtitle: 'Start a session and have students scan the QR code.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: TeacherWireframePalette.borderLight),
        color: TeacherWireframePalette.panelBackground,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          headingRowHeight: 64,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          dividerThickness: 1,
          border: TableBorder.all(
            color: TeacherWireframePalette.borderLight,
            width: 1,
          ),
          columns: [
            const DataColumn(
              label: Text(
                'Roll Number',
                style: TextStyle(
                  color: TeacherWireframePalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'Student Name',
                style: TextStyle(
                  color: TeacherWireframePalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...dates.map(
              (date) => DataColumn(
                label: Text(
                  date,
                  style: const TextStyle(
                    color: TeacherWireframePalette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          rows: rows.map((row) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    row['rollNo']?.toString() ?? '',
                    style: const TextStyle(
                      color: TeacherWireframePalette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    row['name']?.toString() ?? '',
                    style: const TextStyle(
                      color: TeacherWireframePalette.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...dates.map((date) {
                  final status = row[date]?.toString() ?? 'A';
                  final present = status.toUpperCase() == 'P';
                  return DataCell(
                    Center(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: present
                              ? TeacherWireframePalette.textPrimary
                              : TeacherWireframePalette.inactiveText,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CourseDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final String? selectedCourse;
  final ValueChanged<String?> onChanged;
  final bool compact;

  const _CourseDropdown({
    required this.courses,
    required this.selectedCourse,
    required this.onChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
      decoration: BoxDecoration(
        border: Border.all(color: TeacherWireframePalette.borderLight),
        color: TeacherWireframePalette.buttonFill,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCourse,
          onChanged: onChanged,
          iconEnabledColor: TeacherWireframePalette.textPrimary,
          dropdownColor: TeacherWireframePalette.panelBackground,
          style: TextStyle(
            color: TeacherWireframePalette.textPrimary,
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
          items: courses
              .map(
                (course) => DropdownMenuItem<String>(
                  value: course['code'] as String?,
                  child: Text(
                    compact
                        ? (course['code'] as String? ?? '')
                        : '${course['code']} - ${course['name']}',
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DownloadButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: TeacherWireframePalette.border),
        shape: const RoundedRectangleBorder(),
        backgroundColor: TeacherWireframePalette.buttonFill,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_rounded,
            color: TeacherWireframePalette.textPrimary,
            size: 22,
          ),
          SizedBox(width: 8),
          Text(
            'Download Master CSV',
            style: TextStyle(
              color: TeacherWireframePalette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecordsState extends StatelessWidget {
  final String message;
  final String? subtitle;

  const _EmptyRecordsState({
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: TeacherWireframePalette.borderLight),
        color: TeacherWireframePalette.panelBackground,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: TeacherWireframePalette.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                color: TeacherWireframePalette.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

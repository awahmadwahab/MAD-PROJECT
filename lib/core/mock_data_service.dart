class MockDataService {
  // ── Teachers ──
  static final List<Map<String, dynamic>> teachers = [
    {
      'id': 'T001',
      'name': 'Dr. Ali',
      'email': 'ali@campus.edu',
      'password': '1234',
      'department': 'Computer Science',
    },
    {
      'id': 'T002',
      'name': 'Prof. Sara',
      'email': 'sara@campus.edu',
      'password': '1234',
      'department': 'Software Engineering',
    },
  ];

  // ── Courses ──
  static final List<Map<String, dynamic>> courses = [
    {
      'code': 'CS-101',
      'name': 'Data Structures',
      'teacherId': 'T001',
      'time': '09:00 AM - 10:30 AM',
      'room': 'Room 301',
      'days': ['Mon', 'Wed'],
    },
    {
      'code': 'SE-2200',
      'name': 'Software Engineering',
      'teacherId': 'T001',
      'time': '11:00 AM - 12:30 PM',
      'room': 'Room 405',
      'days': ['Tue', 'Thu'],
    },
    {
      'code': 'CS-201',
      'name': 'Algorithm Design',
      'teacherId': 'T002',
      'time': '02:00 PM - 03:30 PM',
      'room': 'Room 202',
      'days': ['Mon', 'Wed', 'Fri'],
    },
  ];

  // ── Students ──
  static final List<Map<String, dynamic>> students = [
    {'rollNo': '2021-CS-01', 'name': 'Ahmed Khan', 'section': 'A'},
    {'rollNo': '2021-CS-02', 'name': 'Fatima Noor', 'section': 'A'},
    {'rollNo': '2021-CS-03', 'name': 'Hassan Ali', 'section': 'A'},
    {'rollNo': '2021-CS-04', 'name': 'Zainab Shah', 'section': 'A'},
    {'rollNo': '2021-CS-05', 'name': 'Omar Raza', 'section': 'B'},
    {'rollNo': '2021-CS-06', 'name': 'Ayesha Malik', 'section': 'B'},
    {'rollNo': '2021-CS-07', 'name': 'Bilal Ahmed', 'section': 'B'},
    {'rollNo': '2021-CS-08', 'name': 'Sana Tariq', 'section': 'B'},
  ];

  // ── Attendance Records ──
  static final List<Map<String, dynamic>> attendanceRecords = [];

  static void markPresent({
    required String rollNo,
    required String studentName,
    required String courseCode,
    required String sessionId,
    required DateTime timestamp,
  }) {
    final exists = attendanceRecords.any((r) =>
        r['rollNo'] == rollNo && r['sessionId'] == sessionId);
    if (exists) return;

    attendanceRecords.add({
      'rollNo': rollNo,
      'studentName': studentName,
      'courseCode': courseCode,
      'sessionId': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'date':
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}',
    });
  }

  static List<Map<String, dynamic>> getRecordsForCourse(String courseCode) {
    return attendanceRecords.where((r) => r['courseCode'] == courseCode).toList();
  }

  static Map<String, dynamic> getMasterSheet(String courseCode) {
    final records = getRecordsForCourse(courseCode);
    final dates = records.map((r) => r['date'] as String).toSet().toList();
    dates.sort();
    final rows = <Map<String, dynamic>>[];
    for (final student in students) {
      final row = <String, dynamic>{
        'rollNo': student['rollNo'],
        'name': student['name'],
      };
      for (final date in dates) {
        final present = records.any(
            (r) => r['rollNo'] == student['rollNo'] && r['date'] == date);
        row[date] = present ? 'P' : 'A';
      }
      rows.add(row);
    }
    return {
      'courseCode': courseCode,
      'dates': dates,
      'rows': rows,
    };
  }

  static Map<String, dynamic>? authenticateTeacher(
      String email, String password) {
    try {
      return teachers.firstWhere(
          (t) => t['email'] == email && t['password'] == password);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? findStudent(String rollNo) {
    try {
      return students.firstWhere((s) => s['rollNo'] == rollNo);
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> getCoursesForTeacher(String teacherId) {
    return courses.where((c) => c['teacherId'] == teacherId).toList();
  }

  static void seedSampleData() {
    final now = DateTime.now();
    for (int dayOffset = 1; dayOffset <= 3; dayOffset++) {
      final date = now.subtract(Duration(days: dayOffset * 2));
      for (int i = 0; i < 5; i++) {
        markPresent(
          rollNo: students[i]['rollNo'] as String,
          studentName: students[i]['name'] as String,
          courseCode: 'CS-101',
          sessionId: 'session-seed-$dayOffset',
          timestamp: date,
        );
      }
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum StudentDeviceBindingStatus {
  linkedNewDevice,
  linkedCurrentDevice,
  studentNotFound,
  linkedToDifferentDevice,
}

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // -- Authentication --
  static Future<UserCredential> signIn(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    return _auth.signOut();
  }

  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // -- Student Authentication --
  static Future<UserCredential> signUpStudent({
    required String email,
    required String password,
    required String rollNo,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user?.uid;
    if (uid != null) {
      // Link Firebase Auth UID to student record
      await _firestore.collection('students').doc(rollNo).update({
        'firebaseUid': uid,
        'email': email,
        'accountCreatedAt': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

  static Future<void> createCourse({
    required String code,
    required String name,
    required String teacherId,
    required String time,
    required String room,
    required List<String> days,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw ArgumentError('Course code cannot be empty.');
    }

    await _firestore.collection('courses').doc(normalizedCode).set({
      'code': normalizedCode,
      'name': name.trim(),
      'teacherId': teacherId.trim(),
      'time': time.trim(),
      'room': room.trim(),
      'days': days,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addStudentToCourse({
    required String courseCode,
    required String studentRollNo,
  }) async {
    final normalizedCourseCode = courseCode.trim().toUpperCase();
    final normalizedRollNo = studentRollNo.trim().toUpperCase();

    if (normalizedCourseCode.isEmpty || normalizedRollNo.isEmpty) {
      throw ArgumentError('Course code and student roll number are required.');
    }

    final courseRef = _firestore
        .collection('courses')
        .doc(normalizedCourseCode);
    final studentRef = _firestore.collection('students').doc(normalizedRollNo);

    await _firestore.runTransaction((transaction) async {
      final courseSnapshot = await transaction.get(courseRef);
      if (!courseSnapshot.exists) {
        throw StateError('Course $normalizedCourseCode was not found.');
      }

      final studentSnapshot = await transaction.get(studentRef);
      if (!studentSnapshot.exists) {
        throw StateError('Student $normalizedRollNo was not found.');
      }

      transaction.update(courseRef, {
        'studentRollNos': FieldValue.arrayUnion([normalizedRollNo]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<UserCredential> signInStudent(
    String email,
    String password,
  ) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<Map<String, dynamic>?> getStudentByFirebaseUid(
    String uid,
  ) async {
    final query = await _firestore
        .collection('students')
        .where('firebaseUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return {'rollNo': query.docs.first.id, ...query.docs.first.data()};
    }
    return null;
  }

  // -- Students --
  static Future<Map<String, dynamic>?> getStudent(String rollNo) async {
    final doc = await _firestore.collection('students').doc(rollNo).get();
    if (!doc.exists) {
      return null;
    }
    return {'rollNo': doc.id, ...?doc.data()};
  }

  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    final query = await _firestore.collection('students').get();
    return query.docs.map((doc) => {'rollNo': doc.id, ...doc.data()}).toList();
  }

  // -- Teachers --
  static Future<Map<String, dynamic>?> getTeacherByEmail(String email) async {
    final query = await _firestore
        .collection('teachers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return {...query.docs.first.data(), 'id': query.docs.first.id};
    }
    return null;
  }

  // -- Courses --
  static Future<List<Map<String, dynamic>>> getCoursesForTeacher(
    String teacherId,
  ) async {
    final query = await _firestore
        .collection('courses')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return query.docs.map((doc) => {'code': doc.id, ...doc.data()}).toList();
  }

  static Future<Map<String, dynamic>?> getCourse(String courseCode) async {
    final doc = await _firestore.collection('courses').doc(courseCode).get();
    return doc.data();
  }

  static Future<StudentDeviceBindingStatus> bindStudentToDeviceIfAllowed({
    required String rollNo,
    required String deviceId,
    required String devicePlatform,
  }) async {
    final normalizedRollNo = rollNo.trim().toUpperCase();
    final normalizedDeviceId = deviceId.trim();
    if (normalizedRollNo.isEmpty || normalizedDeviceId.isEmpty) {
      return StudentDeviceBindingStatus.studentNotFound;
    }

    final studentRef = _firestore.collection('students').doc(normalizedRollNo);

    return _firestore.runTransaction<StudentDeviceBindingStatus>((
      transaction,
    ) async {
      final snapshot = await transaction.get(studentRef);
      if (!snapshot.exists) {
        return StudentDeviceBindingStatus.studentNotFound;
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final boundDeviceId = (data['boundDeviceId'] as String?)?.trim();
      final updatePayload = <String, dynamic>{
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastDevicePlatform': devicePlatform,
      };

      if (boundDeviceId == null || boundDeviceId.isEmpty) {
        transaction.update(studentRef, {
          ...updatePayload,
          'boundDeviceId': normalizedDeviceId,
          'boundAt': FieldValue.serverTimestamp(),
          'boundDevicePlatform': devicePlatform,
        });
        return StudentDeviceBindingStatus.linkedNewDevice;
      }

      if (boundDeviceId == normalizedDeviceId) {
        transaction.update(studentRef, updatePayload);
        return StudentDeviceBindingStatus.linkedCurrentDevice;
      }

      return StudentDeviceBindingStatus.linkedToDifferentDevice;
    });
  }

  // -- Sessions --
  static Future<void> createSession({
    required String sessionId,
    required String courseCode,
    required String teacherId,
    required DateTime startedAt,
  }) async {
    await _firestore.collection('sessions').doc(sessionId).set({
      'sessionId': sessionId,
      'courseCode': courseCode,
      'teacherId': teacherId,
      'active': true,
      'startedAt': Timestamp.fromDate(startedAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getActiveSessionForTeacher(
    String teacherId,
  ) async {
    final query = await _firestore
        .collection('sessions')
        .where('teacherId', isEqualTo: teacherId)
        .where('active', isEqualTo: true)
        .limit(20)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    DateTime readTimestamp(Map<String, dynamic> session) {
      final raw = session['startedAt'];
      if (raw is Timestamp) {
        return raw.toDate();
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final sessions =
        query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList()
          ..sort((a, b) => readTimestamp(b).compareTo(readTimestamp(a)));

    return sessions.first;
  }

  static Future<void> endSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'active': false,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final doc = await _firestore.collection('sessions').doc(sessionId).get();
    if (!doc.exists) {
      return null;
    }

    return {'id': doc.id, ...?doc.data()};
  }

  // -- Attendance --
  static Future<bool> markPresent({
    required String rollNo,
    required String studentName,
    required String courseCode,
    required String sessionId,
    required DateTime timestamp,
    String? teacherId,
  }) async {
    final dateStr =
        '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final recordId = '${sessionId}_$rollNo';
    final attendanceRef = _firestore
        .collection('attendance_records')
        .doc(recordId);

    return _firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(attendanceRef);
      if (existing.exists) {
        return false;
      }

      transaction.set(attendanceRef, {
        'rollNo': rollNo,
        'studentName': studentName,
        'courseCode': courseCode,
        'sessionId': sessionId,
        'teacherId': teacherId,
        'timestamp': timestamp.toIso8601String(),
        'scannedAt': Timestamp.fromDate(timestamp),
        'date': dateStr,
      });
      return true;
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamRecordsForSession(
    String sessionId,
  ) {
    return _firestore
        .collection('attendance_records')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> getRecordsForCourse(
    String courseCode,
  ) async {
    final query = await _firestore
        .collection('attendance_records')
        .where('courseCode', isEqualTo: courseCode)
        .get();
    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamRecordsForCourse(
    String courseCode,
  ) {
    return _firestore
        .collection('attendance_records')
        .where('courseCode', isEqualTo: courseCode)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamRecordsForStudent(
    String rollNo,
  ) {
    return _firestore
        .collection('attendance_records')
        .where('rollNo', isEqualTo: rollNo)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamAllRecords() {
    return _firestore.collection('attendance_records').snapshots();
  }
}

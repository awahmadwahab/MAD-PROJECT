import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'device_security_service.dart';
import 'firebase_service.dart';
import 'offline_vault_service.dart';

class StudentLoginResult {
  final bool success;
  final bool linkedNewDevice;
  final String? errorMessage;

  const StudentLoginResult._({
    required this.success,
    required this.linkedNewDevice,
    this.errorMessage,
  });

  const StudentLoginResult.success({required bool linkedNewDevice})
    : this._(
        success: true,
        linkedNewDevice: linkedNewDevice,
        errorMessage: null,
      );

  const StudentLoginResult.failure(String message)
    : this._(success: false, linkedNewDevice: false, errorMessage: message);
}

/// Central app state managed by Provider.
class AppState extends ChangeNotifier {
  // Firebase references
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth state
  String? _currentRole; // 'teacher' or 'student'
  Map<String, dynamic>? _currentTeacher;
  Map<String, dynamic>? _currentStudent;

  // Session state
  String? _activeSessionId;
  String? _activeCoursecode;
  bool _sessionActive = false;

  // Offline vault sync loop
  Timer? _offlineSyncTimer;
  bool _offlineSyncInProgress = false;
  StreamSubscription<User?>? _authSubscription;

  bool _authInitialized = false;
  bool _isUnlocked = false;

  AppState() {
    _initAuthListener();
    _startOfflineSyncLoop();
  }

  void _initAuthListener() {
    _authSubscription = FirebaseService.authStateChanges().listen((
      User? user,
    ) async {
      if (user == null) {
        _currentTeacher = null;
        _currentStudent = null;
        _currentRole = null;
        _sessionActive = false;
        _activeSessionId = null;
        _activeCoursecode = null;
        _isUnlocked = false;
        _authInitialized = true;
        notifyListeners();
      } else {
        if (user.email != null) {
          // Check if teacher first
          final teacherInfo = await FirebaseService.getTeacherByEmail(
            user.email!,
          );
          if (teacherInfo != null) {
            final teacherId = teacherInfo['id'] as String? ?? '';
            _currentTeacher = teacherInfo;
            _currentStudent = null;
            _currentRole = 'teacher';
            _isUnlocked = true; // Teacher doesn't need biometric lock yet
            _authInitialized = true;
            await _restoreActiveSessionForTeacher(teacherId);
            notifyListeners();
          } else {
            // Check if student (by Firebase UID)
            final studentInfo = await FirebaseService.getStudentByFirebaseUid(
              user.uid,
            );
            if (studentInfo != null) {
              _currentStudent = studentInfo;
              _currentTeacher = null;
              _currentRole = 'student';
              _authInitialized = true;
              notifyListeners();
            } else {
              _authInitialized = true;
              await FirebaseService.signOut();
            }
          }
        }

        // Whenever auth state flips to online user, retry pending offline records.
        await syncOfflineVaultNow();
      }
    });
  }

  Future<void> _restoreActiveSessionForTeacher(String teacherId) async {
    if (teacherId.trim().isEmpty) {
      _sessionActive = false;
      _activeSessionId = null;
      _activeCoursecode = null;
      return;
    }

    try {
      final session = await FirebaseService.getActiveSessionForTeacher(
        teacherId,
      );
      if (session == null) {
        _sessionActive = false;
        _activeSessionId = null;
        _activeCoursecode = null;
        return;
      }

      final sessionId =
          (session['sessionId'] as String?) ?? (session['id'] as String?);
      final courseCode = session['courseCode'] as String?;
      _activeSessionId = sessionId;
      _activeCoursecode = courseCode;
      _sessionActive = sessionId != null && courseCode != null;
    } catch (_) {
      _sessionActive = false;
      _activeSessionId = null;
      _activeCoursecode = null;
    }
  }

  void _startOfflineSyncLoop() {
    _offlineSyncTimer?.cancel();
    _offlineSyncTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => syncOfflineVaultNow(),
    );
  }

  Future<int> syncOfflineVaultNow() async {
    if (_offlineSyncInProgress) {
      return 0;
    }

    _offlineSyncInProgress = true;
    try {
      final syncedCount = await OfflineVaultService.syncRecords();
      if (syncedCount > 0) {
        await OfflineVaultService.removeSyncedRecords();
      }
      return syncedCount;
    } catch (_) {
      // Expected while device is offline or backend is temporarily unreachable.
      return 0;
    } finally {
      _offlineSyncInProgress = false;
    }
  }

  // Getters
  String? get currentRole => _currentRole;
  Map<String, dynamic>? get currentTeacher => _currentTeacher;
  Map<String, dynamic>? get currentStudent => _currentStudent;
  String? get activeSessionId => _activeSessionId;
  String? get activeCourseCode => _activeCoursecode;
  bool get sessionActive => _sessionActive;
  bool get isLoggedIn => _currentTeacher != null || _currentStudent != null;
  bool get isUnlocked => _isUnlocked;
  bool get authInitialized => _authInitialized;

  void unlockApp() {
    _isUnlocked = true;
    notifyListeners();
  }

  // Teacher Auth
  Future<bool> loginTeacher(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return false;
    }

    try {
      final userCredential = await FirebaseService.signIn(email, password);
      final user = userCredential.user;
      if (user != null && user.email != null) {
        final teacher = await FirebaseService.getTeacherByEmail(user.email!);
        if (teacher != null) {
          final teacherId = teacher['id'] as String? ?? '';
          _currentTeacher = teacher;
          _currentStudent = null;
          _currentRole = 'teacher';
          _isUnlocked = true;
          await _restoreActiveSessionForTeacher(teacherId);
          notifyListeners();
          return true;
        }
        await FirebaseService.signOut();
      }
    } catch (_) {
      debugPrint('Error logging in teacher.');
    }
    return false;
  }

  // Student Auth
  Future<StudentLoginResult> loginStudent(String rollNo) async {
    final normalizedRollNo = rollNo.trim().toUpperCase();
    if (normalizedRollNo.isEmpty) {
      return const StudentLoginResult.failure('Please enter your roll number.');
    }

    try {
      final student = await FirebaseService.getStudent(normalizedRollNo);
      if (student != null) {
        final deviceId = await DeviceSecurityService.getOrCreateDeviceId();
        final bindingStatus =
            await FirebaseService.bindStudentToDeviceIfAllowed(
              rollNo: normalizedRollNo,
              deviceId: deviceId,
              devicePlatform: DeviceSecurityService.platformLabel,
            );

        if (bindingStatus == StudentDeviceBindingStatus.studentNotFound) {
          return const StudentLoginResult.failure('Roll number not found.');
        }
        if (bindingStatus ==
            StudentDeviceBindingStatus.linkedToDifferentDevice) {
          return const StudentLoginResult.failure(
            'This student account is already linked to another device. Contact your teacher to reset device binding.',
          );
        }

        _currentStudent = student;
        _currentTeacher = null;
        _currentRole = 'student';
        _isUnlocked = true; // newly logged in
        notifyListeners();

        // Attempt to flush previously queued scans right after student login.
        await syncOfflineVaultNow();
        return StudentLoginResult.success(
          linkedNewDevice:
              bindingStatus == StudentDeviceBindingStatus.linkedNewDevice,
        );
      }
    } catch (_) {
      debugPrint('Error logging in student.');
      return const StudentLoginResult.failure(
        'Unable to verify student account right now. Please check internet and try again.',
      );
    }

    return const StudentLoginResult.failure('Roll number not found.');
  }

  // Student Authentication with Firebase Auth
  Future<StudentLoginResult> registerStudent({
    required String email,
    required String password,
    required String rollNo,
  }) async {
    final normalizedRollNo = rollNo.trim().toUpperCase();
    if (normalizedRollNo.isEmpty || email.trim().isEmpty || password.isEmpty) {
      return const StudentLoginResult.failure('Please fill in all fields.');
    }

    try {
      // Verify student exists in database
      final student = await FirebaseService.getStudent(normalizedRollNo);
      if (student == null) {
        return const StudentLoginResult.failure('Roll number not found.');
      }

      // Create Firebase Auth account
      await FirebaseService.signUpStudent(
        email: email.trim(),
        password: password,
        rollNo: normalizedRollNo,
      );

      // Bind device after successful signup
      final deviceId = await DeviceSecurityService.getOrCreateDeviceId();
      final bindingStatus = await FirebaseService.bindStudentToDeviceIfAllowed(
        rollNo: normalizedRollNo,
        deviceId: deviceId,
        devicePlatform: DeviceSecurityService.platformLabel,
      );

      if (bindingStatus == StudentDeviceBindingStatus.linkedToDifferentDevice) {
        return const StudentLoginResult.failure(
          'This student account is already linked to another device. Contact your teacher to reset device binding.',
        );
      }

      _currentStudent = student;
      _currentTeacher = null;
      _currentRole = 'student';
      _isUnlocked = true; // newly logged in
      notifyListeners();

      await syncOfflineVaultNow();
      return StudentLoginResult.success(
        linkedNewDevice:
            bindingStatus == StudentDeviceBindingStatus.linkedNewDevice,
      );
    } catch (e) {
      debugPrint('Error registering student: $e');
      return StudentLoginResult.failure(
        'Registration failed. This email may already be in use.',
      );
    }
  }

  Future<StudentLoginResult> loginStudentWithAuth({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const StudentLoginResult.failure(
        'Please enter email and password.',
      );
    }

    try {
      // Sign in with Firebase Auth
      await FirebaseService.signInStudent(email.trim(), password);

      // Get current user
      final user = _auth.currentUser;
      if (user?.uid == null) {
        return const StudentLoginResult.failure('Authentication failed.');
      }

      // Get student info by Firebase UID
      final student = await FirebaseService.getStudentByFirebaseUid(user!.uid);
      if (student == null) {
        await FirebaseService.signOut();
        return const StudentLoginResult.failure('Student record not found.');
      }

      // Bind device
      final deviceId = await DeviceSecurityService.getOrCreateDeviceId();
      final rollNo = student['rollNo'] as String? ?? '';
      final bindingStatus = await FirebaseService.bindStudentToDeviceIfAllowed(
        rollNo: rollNo,
        deviceId: deviceId,
        devicePlatform: DeviceSecurityService.platformLabel,
      );

      if (bindingStatus == StudentDeviceBindingStatus.linkedToDifferentDevice) {
        await FirebaseService.signOut();
        return const StudentLoginResult.failure(
          'This student account is already linked to another device. Contact your teacher to reset device binding.',
        );
      }

      _currentStudent = student;
      _currentTeacher = null;
      _currentRole = 'student';
      notifyListeners();

      await syncOfflineVaultNow();
      return StudentLoginResult.success(
        linkedNewDevice:
            bindingStatus == StudentDeviceBindingStatus.linkedNewDevice,
      );
    } catch (e) {
      debugPrint('Error logging in student: $e');
      return const StudentLoginResult.failure(
        'Login failed. Check your email and password.',
      );
    }
  }

  // Session Management
  Future<bool> startSession(String courseCode) async {
    final teacherId = _currentTeacher?['id'] as String?;
    if (teacherId == null) {
      return false;
    }

    try {
      final existingSession = await FirebaseService.getActiveSessionForTeacher(
        teacherId,
      );
      final existingSessionId =
          existingSession?['sessionId'] as String? ??
          existingSession?['id'] as String?;
      if (existingSessionId != null && existingSessionId.isNotEmpty) {
        await FirebaseService.endSession(existingSessionId);
      }

      final sessionId = const Uuid().v4();
      final startedAt = DateTime.now();

      await FirebaseService.createSession(
        sessionId: sessionId,
        courseCode: courseCode,
        teacherId: teacherId,
        startedAt: startedAt,
      );

      _activeSessionId = sessionId;
      _activeCoursecode = courseCode;
      _sessionActive = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> endSession() async {
    final sessionId = _activeSessionId;
    if (sessionId != null) {
      await FirebaseService.endSession(sessionId);
    }

    _sessionActive = false;
    _activeSessionId = null;
    _activeCoursecode = null;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    if (_sessionActive && _currentRole == 'teacher') {
      await endSession();
    }
    await FirebaseService.signOut();

    _currentTeacher = null;
    _currentStudent = null;
    _currentRole = null;
    _sessionActive = false;
    _activeSessionId = null;
    _activeCoursecode = null;
    _isUnlocked = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _offlineSyncTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

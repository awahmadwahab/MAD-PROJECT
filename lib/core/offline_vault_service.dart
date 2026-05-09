import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

class OfflineVaultService {
  static const String _vaultKey = 'offline_attendance_vault';

  static Future<void> saveRecord({
    required String studentId,
    required String studentName,
    required String sessionId,
    required String courseCode,
    required DateTime scannedAt,
    String? teacherId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_vaultKey) ?? [];

    final alreadyQueued = existing.any((entry) {
      final record = jsonDecode(entry) as Map<String, dynamic>;
      return record['studentId'] == studentId &&
          record['sessionId'] == sessionId;
    });
    if (alreadyQueued) {
      return;
    }

    final record = {
      'studentId': studentId,
      'studentName': studentName,
      'sessionId': sessionId,
      'courseCode': courseCode,
      'teacherId': teacherId,
      'queuedAt': DateTime.now().toIso8601String(),
      'scannedAt': scannedAt.toIso8601String(),
      'synced': false,
    };

    existing.add(jsonEncode(record));
    await prefs.setStringList(_vaultKey, existing);
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_vaultKey) ?? [];

    return raw
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .where((record) => record['synced'] != true)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_vaultKey) ?? [];

    return raw
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .toList();
  }

  static Future<int> syncRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_vaultKey) ?? [];
    int syncedCount = 0;
    final updatedRecords = <String>[];

    for (final entry in raw) {
      final record = jsonDecode(entry) as Map<String, dynamic>;

      if (record['synced'] == true) {
        updatedRecords.add(jsonEncode(record));
        continue;
      }

      try {
        final created = await FirebaseService.markPresent(
          rollNo: record['studentId'] as String? ?? '',
          studentName: record['studentName'] as String? ?? '',
          courseCode: record['courseCode'] as String? ?? '',
          sessionId: record['sessionId'] as String? ?? '',
          teacherId: record['teacherId'] as String?,
          timestamp: DateTime.parse(record['scannedAt'] as String),
        );
        // If attendance already exists for this session/student pair, treat it
        // as synced so the queue doesn't get stuck retrying forever.
        record['synced'] = true;
        if (created) {
          syncedCount++;
        }
      } catch (_) {
        // Keep the record queued for a later retry.
      }

      updatedRecords.add(jsonEncode(record));
    }

    await prefs.setStringList(_vaultKey, updatedRecords);
    return syncedCount;
  }

  static Future<bool> hasPendingRecords() async {
    final pending = await getUnsyncedRecords();
    return pending.isNotEmpty;
  }

  static Future<int> getPendingCount() async {
    final pending = await getUnsyncedRecords();
    return pending.length;
  }

  static Future<void> removeSyncedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_vaultKey) ?? [];

    final remaining = raw.where((entry) {
      final record = jsonDecode(entry) as Map<String, dynamic>;
      return record['synced'] != true;
    }).toList();

    await prefs.setStringList(_vaultKey, remaining);
  }

  static Future<int> getRecordCount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_vaultKey) ?? [];
    return raw.length;
  }

  static Future<void> clearVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vaultKey);
  }
}

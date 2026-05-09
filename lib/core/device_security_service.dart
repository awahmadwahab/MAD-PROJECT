import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local device identity for student account binding.
///
/// This is an install-level fingerprint. On first login, the student profile
/// is linked to this identifier and subsequent logins from other devices are blocked.
class DeviceSecurityService {
  static const String _deviceIdKey = 'campuscan_device_id_v1';

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = const Uuid().v4();
    await prefs.setString(_deviceIdKey, created);
    return created;
  }

  static String get platformLabel {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}

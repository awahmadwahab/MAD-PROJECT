import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// QR security layer for CampuScan.
///
/// The payload is short-lived (10s), includes a nonce, and carries a signature
/// so modified QR JSON is rejected by the student app.
class QrSecurityService {
  static const int validityWindowMs = 10000; // 10 seconds
  static const int allowedFutureSkewMs = 2000;

  // For semester-project scope this is acceptable. For production, move
  // signing to a trusted backend or Cloud Function and rotate secret regularly.
  static const String _appSecret = 'campuscan_qr_signing_secret_v1_2026';

  /// Generate a fresh signed QR payload string.
  static String generatePayload({
    required String sessionId,
    required String courseCode,
    required String teacherId,
  }) {
    final issuedAtMs = DateTime.now().millisecondsSinceEpoch;
    final expiresAtMs = issuedAtMs + validityWindowMs;
    final nonce = _generateNonce(12);

    final canonical = _canonicalString(
      sessionId: sessionId,
      courseCode: courseCode,
      teacherId: teacherId,
      issuedAtMs: issuedAtMs,
      expiresAtMs: expiresAtMs,
      nonce: nonce,
    );
    final signature = _sign(canonical);

    final payload = {
      'v': 2,
      'sessionId': sessionId,
      'courseCode': courseCode,
      'teacherId': teacherId,
      'issuedAt': issuedAtMs,
      'expiresAt': expiresAtMs,
      'nonce': nonce,
      'sig': signature,
    };

    return jsonEncode(payload);
  }

  /// Validate scanned QR payload.
  /// Returns `{ valid: bool, data?: Map, error?: String }`.
  static Map<String, dynamic> validatePayload(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map<String, dynamic>) {
        return {'valid': false, 'error': 'Invalid QR format'};
      }

      final data = decoded;
      final sessionId = data['sessionId']?.toString();
      final courseCode = data['courseCode']?.toString();
      final teacherId = data['teacherId']?.toString();
      final nonce = data['nonce']?.toString();
      final signature = data['sig']?.toString();
      final issuedAtMs = _toInt(data['issuedAt']);
      final expiresAtMs = _toInt(data['expiresAt']);

      // Direct null checks to allow Dart's flow analysis to promote variables
      // to non-nullable types in the subsequent logic.
      if (sessionId == null ||
          courseCode == null ||
          teacherId == null ||
          nonce == null ||
          signature == null ||
          issuedAtMs == null ||
          expiresAtMs == null) {
        return {'valid': false, 'error': 'Invalid QR format'};
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      if (issuedAtMs - now > allowedFutureSkewMs) {
        return {
          'valid': false,
          'error': 'Invalid QR timestamp (future date)',
          'data': data,
        };
      }

      if (now > expiresAtMs) {
        final elapsed = now - expiresAtMs;
        return {
          'valid': false,
          'error':
              'QR code expired (${(elapsed / 1000).toStringAsFixed(1)}s late)',
          'data': data,
        };
      }

      if ((expiresAtMs - issuedAtMs) > (validityWindowMs + allowedFutureSkewMs)) {
        return {
          'valid': false,
          'error': 'Invalid QR validity window',
          'data': data,
        };
      }

      final expectedSig = _sign(
        _canonicalString(
          sessionId: sessionId,
          courseCode: courseCode,
          teacherId: teacherId,
          issuedAtMs: issuedAtMs,
          expiresAtMs: expiresAtMs,
          nonce: nonce,
        ),
      );

      if (!_constantTimeEquals(signature, expectedSig)) {
        return {
          'valid': false,
          'error': 'QR signature mismatch',
          'data': data,
        };
      }

      return {
        'valid': true,
        'data': {
          'sessionId': sessionId,
          'courseCode': courseCode,
          'teacherId': teacherId,
          'issuedAt': issuedAtMs,
          'expiresAt': expiresAtMs,
          'nonce': nonce,
        },
      };
    } catch (e) {
      return {'valid': false, 'error': 'Failed to parse QR: $e'};
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String _canonicalString({
    required String sessionId,
    required String courseCode,
    required String teacherId,
    required int issuedAtMs,
    required int expiresAtMs,
    required String nonce,
  }) {
    return [
      sessionId,
      courseCode,
      teacherId,
      issuedAtMs,
      expiresAtMs,
      nonce,
    ].join('|');
  }

  static String _sign(String canonical) {
    final bytes = utf8.encode('$canonical|$_appSecret');
    return sha256.convert(bytes).toString();
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    var mismatch = 0;
    for (var i = 0; i < a.length; i++) {
      mismatch |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return mismatch == 0;
  }

  static String _generateNonce(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sends SMS directly using Android SmsManager via platform channel.
class SmsService {
  static const _channel = MethodChannel('com.safealert/sms');

  /// Request SEND_SMS permission at runtime. Returns true if granted.
  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Check if SEND_SMS permission is already granted.
  static Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Send SMS directly without opening the messaging app.
  /// Returns true on success, false on failure.
  static Future<bool> sendSMS({
    required String phone,
    required String message,
  }) async {
    try {
      final granted = await hasPermission();
      if (!granted) {
        final requested = await requestPermission();
        if (!requested) return false;
      }

      final result = await _channel.invokeMethod('sendSMS', {
        'phone': phone,
        'message': message,
      });
      return result == true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Build the SOS SMS body with all required fields.
  static String buildSOSMessage({
    required String userName,
    required String distressMessage,
    required double latitude,
    required double longitude,
    required String timestamp,
  }) {
    final name = userName.isNotEmpty ? userName : 'SafeAlert User';
    final locationLink = 'https://maps.google.com/?q=$latitude,$longitude';

    return 'SOS ALERT\n'
        'Name: $name\n'
        'Emergency: $distressMessage\n'
        'Location: $locationLink\n'
        'Time: $timestamp';
  }
}

import 'package:flutter/services.dart';

/// Flutter wrapper for the native Android ShakeDetectionService.
/// Controls the foreground service that monitors accelerometer in background.
class ShakeBackgroundService {
  static const _channel = MethodChannel('com.safealert/shake_service');

  // Callback for when shake is triggered from background
  static Function? _onShakeTriggered;

  /// Set up listener for shake triggers from the native service.
  /// Must be called early in app lifecycle.
  static void setOnShakeTriggered(Function callback) {
    _onShakeTriggered = callback;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShakeTriggered') {
        _onShakeTriggered?.call();
      }
    });
  }

  /// Check if there's a pending shake trigger (app was launched by shake).
  static Future<bool> checkPendingTrigger() async {
    try {
      final result = await _channel.invokeMethod('checkPendingTrigger');
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  /// Start the background shake detection foreground service.
  static Future<bool> start({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    try {
      final result = await _channel.invokeMethod('startService', {
        'supabaseUrl': supabaseUrl,
        'supabaseKey': supabaseKey,
      });
      return result == true;
    } on PlatformException catch (e) {
      print('Failed to start shake service: ${e.message}');
      return false;
    }
  }

  /// Stop the background shake detection service.
  static Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod('stopService');
      return result == true;
    } on PlatformException catch (e) {
      print('Failed to stop shake service: ${e.message}');
      return false;
    }
  }

  /// Check if the background shake service is currently running.
  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod('isRunning');
      return result == true;
    } on PlatformException {
      return false;
    }
  }
}

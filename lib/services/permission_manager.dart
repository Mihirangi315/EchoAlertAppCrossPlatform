import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Manages runtime permissions for EchoAlert audio monitoring.
class PermissionManager {
  /// Request Microphone and Notification permissions required for EchoAlert.
  /// On Web, returns true immediately (browser handles its own permission dialog).
  static Future<bool> requestAudioPermissions() async {
    if (kIsWeb) return true;

    try {
      final statuses = await [
        ph.Permission.microphone,
        ph.Permission.notification,
      ].request();

      final micGranted = statuses[ph.Permission.microphone]?.isGranted ?? false;
      // Notification permission is optional — don't block on it
      final notifGranted = statuses[ph.Permission.notification]?.isGranted ?? true;

      if (!micGranted) {
        debugPrint('PermissionManager: Microphone permission DENIED');
        return false;
      }

      debugPrint('PermissionManager: Mic=$micGranted, Notifications=$notifGranted');
      return true;
    } catch (e) {
      debugPrint('PermissionManager: Permission request error ($e)');
      // On unsupported platforms (desktop/web fallback), allow proceeding
      return true;
    }
  }

  /// Check if microphone permission is currently granted without requesting.
  static Future<bool> isMicrophonePermissionGranted() async {
    if (kIsWeb) return true;
    try {
      return await ph.Permission.microphone.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Check if microphone permission is permanently denied (user tapped "Never ask again").
  static Future<bool> isMicrophonePermanentlyDenied() async {
    if (kIsWeb) return false;
    try {
      return await ph.Permission.microphone.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Open the app's system settings page so user can manually grant permission.
  static Future<void> openAppSettings() async {
    if (kIsWeb) return;
    try {
      await ph.openAppSettings();
    } catch (e) {
      debugPrint('PermissionManager: Could not open app settings: $e');
    }
  }
}

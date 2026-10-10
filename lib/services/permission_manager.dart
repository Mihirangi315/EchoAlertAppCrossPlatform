import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  /// Request Microphone and Notification permissions required for EchoAlert audio monitoring.
  static Future<bool> requestAudioPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.notification,
    ].request();

    bool micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    bool notificationGranted = statuses[Permission.notification]?.isGranted ?? true;

    return micGranted && notificationGranted;
  }

  /// Check if microphone permission is currently granted.
  static Future<bool> isMicrophonePermissionGranted() async {
    return await Permission.microphone.isGranted;
  }
}

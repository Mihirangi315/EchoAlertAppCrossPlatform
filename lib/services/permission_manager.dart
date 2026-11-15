import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Member E: Permission Manager
///
/// Centralized runtime permission handling for EchoAlert.
/// Gracefully manages runtime permissions for Microphone (`RECORD_AUDIO`)
/// and Notifications (`POST_NOTIFICATIONS`) with user-friendly rationale dialogs.
class PermissionManager {
  /// Request both Microphone and Notification permissions required for EchoAlert.
  /// Returns `true` if microphone permission is granted (notifications are optional).
  static Future<bool> requestAudioPermissions() async {
    if (kIsWeb) return true;

    try {
      final statuses = await [
        ph.Permission.microphone,
        ph.Permission.notification,
      ].request();

      final micStatus = statuses[ph.Permission.microphone];
      final notifStatus = statuses[ph.Permission.notification];

      final micGranted = micStatus?.isGranted ?? false;
      final notifGranted = notifStatus?.isGranted ?? true;

      debugPrint(
        'PermissionManager: Mic=$micGranted (${micStatus?.name}), Notifications=$notifGranted (${notifStatus?.name})',
      );

      return micGranted;
    } catch (e) {
      debugPrint('PermissionManager: Permission request error ($e)');
      // On unsupported platforms / desktop fallbacks, allow proceeding
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

  /// Check if microphone permission is permanently denied ("Never ask again").
  static Future<bool> isMicrophonePermanentlyDenied() async {
    if (kIsWeb) return false;
    try {
      return await ph.Permission.microphone.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Check if notification permission is currently granted.
  static Future<bool> isNotificationPermissionGranted() async {
    if (kIsWeb) return true;
    try {
      return await ph.Permission.notification.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Request notification permission explicitly (e.g. from Settings screen).
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await ph.Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return true;
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

  /// Shows an accessible, clear Material 3 rationale dialog explaining
  /// why microphone permission is required before directing to settings.
  static Future<void> showMicrophoneRationaleDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    final isPermanent = await isMicrophonePermanentlyDenied();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.mic_off_rounded,
          color: Colors.redAccent,
          size: 48,
        ),
        title: const Text(
          'Microphone Permission Required',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EchoAlert continuously listens to your surrounding environment to identify critical sounds in real time:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildFeatureBullet(
              Icons.warning_amber_rounded,
              'Smoke & fire alarms for safety',
            ),
            _buildFeatureBullet(
              Icons.doorbell_outlined,
              'Doorbells and door knocking',
            ),
            _buildFeatureBullet(
              Icons.child_care_outlined,
              'Baby crying and phone ringing',
            ),
            const SizedBox(height: 12),
            Text(
              isPermanent
                  ? 'Microphone permission was permanently denied. Please enable it in your device settings to start listening.'
                  : 'Audio is processed entirely on-device and is never recorded or uploaded to the cloud.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: Icon(isPermanent ? Icons.settings : Icons.check),
            label: Text(isPermanent ? 'Open Settings' : 'Grant Permission'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (isPermanent) {
                await openAppSettings();
              } else {
                final granted = await requestAudioPermissions();
                if (granted && onRetry != null) {
                  onRetry();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  /// Shows an accessible dialog explaining why notification permission is needed.
  static Future<void> showNotificationRationaleDialog(
    BuildContext context, {
    VoidCallback? onGranted,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.notifications_active_outlined,
          color: Colors.amber,
          size: 48,
        ),
        title: const Text(
          'Enable Notifications',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'EchoAlert sends high-priority visual notifications and distinct vibration patterns when safety-critical sounds (like smoke alarms or doorbells) are detected while your screen is off or the app is in the background.\n\n'
          'Would you like to enable notifications?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final granted = await requestNotificationPermission();
              if (granted && onGranted != null) {
                onGranted();
              }
            },
            child: const Text('Enable Notifications'),
          ),
        ],
      ),
    );
  }

  static Widget _buildFeatureBullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

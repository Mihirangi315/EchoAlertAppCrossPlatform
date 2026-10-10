import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../database/app_database.dart';
import '../models/detection_event.dart';
import '../screens/alert_overlay.dart';

class AlertManager {
  AlertManager._();
  static final AlertManager instance = AlertManager._();

  /// MaterialApp එකට මේක දෙන්න ඕන (Alert Overlay එක පෙන්වන්න)
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _lastAlert = {};
  bool _initialized = false;
  bool _overlayOpen = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'echoalert_alerts',
    'Sound Alerts',
    description: 'Alerts when an important sound is detected',
    importance: Importance.max,
    enableVibration: false, // vibration එක අපි වෙනම කරනවා
  );

  // [රැඳී ඉන්න ms, vibrate ms, රැඳී ඉන්න ms, vibrate ms, ...]
  static const Map<String, List<int>> _patterns = {
    'doorbell': [0, 400, 200, 400],
    'smoke / fire alarm': [0, 800, 200, 800, 200, 800],
    'baby crying': [0, 200, 100, 200, 100, 200, 100, 200],
    'phone ringing': [0, 500, 300, 500],
    'door knocking': [0, 150, 100, 150, 100, 150],
  };

  /// "Smoke Alarm" වගේ වෙනස් නම් ආවත් එකම sound එකක් විදියට හඳුනාගන්නවා
  String _normalize(String label) {
    final l = label.toLowerCase();
    if (l.contains('smoke') || l.contains('fire')) return 'smoke / fire alarm';
    return l;
  }

  Future<void> init() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Member C ගේ detection එකෙන් මේක call කරන්න ඕන
  Future<void> handleDetection(String label, double confidence) async {
    final settings = await AppDatabase.instance.getSettings();
    final matches =
        settings.where((s) => _normalize(s.soundLabel) == _normalize(label));
    if (matches.isEmpty) return;
    final setting = matches.first;

    // user disable කරලා නම් හෝ confidence මදි නම් alert නැහැ
    if (!setting.isEnabled || confidence < setting.sensitivity) return;

    // එකම sound එකට තත්පර 5ක් ඇතුලත ආයෙත් alert නොකරන්න
    final now = DateTime.now();
    final last = _lastAlert[setting.soundLabel];
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      return;
    }
    _lastAlert[setting.soundLabel] = now;

    await _fireAlert(setting.soundLabel, confidence);
    await AppDatabase.instance.insertEvent(DetectionEvent(
      soundLabel: setting.soundLabel,
      confidence: confidence,
      timestamp: now,
    ));
  }

  /// Settings screen එකේ "Test" button වලට (database/cooldown නැතුව)
  Future<void> showTestAlert(String label) => _fireAlert(label, 0.99);

  Future<void> _fireAlert(String label, double confidence) async {
    await _vibrate(label);
    await _showNotification(label, confidence);
    _showOverlay(label, confidence);
  }

  Future<void> _vibrate(String label) async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(
        pattern: _patterns[_normalize(label)] ?? [0, 500, 200, 500],
      );
    }
  }

  Future<void> _showNotification(String label, double confidence) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'echoalert_alerts',
        'Sound Alerts',
        channelDescription: 'Alerts when an important sound is detected',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        enableVibration: false,
        visibility: NotificationVisibility.public,
      ),
    );
    await _plugin.show(
      id: label.hashCode & 0x7fffffff,
      title: '$label detected!',
      body: 'Confidence ${(confidence * 100).toStringAsFixed(0)}%',
      notificationDetails: details,
      payload: '$label|$confidence',
    );
  }

  void _showOverlay(String label, double confidence) {
    final context = navigatorKey.currentContext;
    if (context == null || _overlayOpen) return;
    _overlayOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          AlertOverlay(detectedSound: label, confidence: confidence),
    ).then((_) {
      _overlayOpen = false;
      Vibration.cancel(); // Dismiss කළාම vibration නවතිනවා
    });
  }

  void _onNotificationTap(NotificationResponse response) {
    final parts = (response.payload ?? '').split('|');
    if (parts.first.isEmpty) return;
    final confidence = parts.length > 1 ? double.tryParse(parts[1]) ?? 0.0 : 0.0;
    _showOverlay(parts.first, confidence);
  }
}
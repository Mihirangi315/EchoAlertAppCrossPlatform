import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../models/detection_result.dart';
import 'alert_manager.dart';
import 'sound_classification_engine.dart';


class DetectionBridge {
  DetectionBridge._();
  static final DetectionBridge instance = DetectionBridge._();

  
  static const Map<String, String> _engineCategory = {
    'Doorbell': 'Doorbell',
    'Smoke / Fire Alarm': 'Smoke Alarm',
    'Baby crying': 'Baby Crying',
    'Phone ringing': 'Phone Ringing',
    'Door knocking': 'Door Knocking',
  };

  StreamSubscription<DetectionResult>? _subscription;

  Future<void> start() async {
    
    if (kIsWeb) return;
    await syncSettings();
    _subscription ??= SoundClassificationEngine().detectionStream.listen(
      (detection) async {
        try {
          await AlertManager.instance
              .handleDetection(detection.category, detection.confidence);
        } catch (e) {
          debugPrint('DetectionBridge error: $e');
        }
      },
    );
  }

  
  Future<void> syncSettings() async {
    if (kIsWeb) return;
    final engine = SoundClassificationEngine();
    final settings = await AppDatabase.instance.getSettings();
    for (final s in settings) {
      final category = _engineCategory[s.soundLabel];
      if (category == null) continue;
      engine.updateSensitivity(category, s.sensitivity);
      engine.toggleCategory(category, s.isEnabled);
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

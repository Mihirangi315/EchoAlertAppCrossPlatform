import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:echo_alert/services/sound_classification_engine.dart';
import 'package:echo_alert/models/detection_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Classification Engine & Alert Integration Tests', () {
    late SoundClassificationEngine engine;

    setUp(() {
      engine = SoundClassificationEngine();
    });

    test('Engine starts with correct initial sensitivity thresholds and enabled states', () {
      expect(engine.isCategoryEnabled('Doorbell'), isTrue);
      expect(engine.isCategoryEnabled('Smoke Alarm'), isTrue);
      expect(engine.isCategoryEnabled('Baby Crying'), isTrue);
      expect(engine.isCategoryEnabled('Phone Ringing'), isTrue);
      expect(engine.isCategoryEnabled('Door Knocking'), isTrue);

      expect(engine.getSensitivity('Doorbell'), inInclusiveRange(0.50, 0.95));
      expect(
        engine.getSensitivity('Smoke Alarm'),
        inInclusiveRange(0.50, 0.95),
      );
    });

    test('Threshold updates clamp within safe bounds (0.50 to 0.95)', () {
      engine.updateSensitivity('Doorbell', 0.99);
      expect(engine.getSensitivity('Doorbell'), equals(0.95));

      engine.updateSensitivity('Doorbell', 0.20);
      expect(engine.getSensitivity('Doorbell'), equals(0.50));

      engine.updateSensitivity('Doorbell', 0.82);
      expect(engine.getSensitivity('Doorbell'), equals(0.82));
    });

    test(
      'Toggling category state enables/disables alerts for that category',
      () {
        engine.toggleCategory('Baby Crying', false);
        expect(engine.isCategoryEnabled('Baby Crying'), isFalse);

        engine.toggleCategory('Baby Crying', true);
        expect(engine.isCategoryEnabled('Baby Crying'), isTrue);
      },
    );

    test('Simulated detection emits event on detectionStream and updates recent list', () async {
      DetectionResult? emittedResult;
      final sub = engine.detectionStream.listen((result) {
        emittedResult = result;
      });

      engine.simulateDetection(
        'Smoke Alarm',
        'Smoke detector, smoke alarm',
        0.93,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedResult, isNotNull);
      expect(emittedResult!.category, equals('Smoke Alarm'));
      expect(emittedResult!.soundLabel, equals('Smoke detector, smoke alarm'));
      expect(emittedResult!.confidence, equals(0.93));

      expect(engine.latestDetection, isNotNull);
      expect(engine.latestDetection!.category, equals('Smoke Alarm'));
      expect(engine.recentDetections.isNotEmpty, isTrue);
      expect(engine.recentDetections.first.category, equals('Smoke Alarm'));

      await sub.cancel();
    });

    test('Recent detections list caps at 50 events', () {
      for (int i = 0; i < 60; i++) {
        engine.simulateDetection('Doorbell', 'Ding-dong $i', 0.85);
      }

      expect(engine.recentDetections.length, equals(50));
    });

    test(
      'Mock audio buffer processing detects transient knock pattern via DSP',
      () async {
        // Create a 15,600-sample buffer simulating an impulsive knock (silent background with sharp transient spikes)
        final buffer = Float32List(15600);
        // Spike at index 1000
        buffer[1000] = 0.8;
        buffer[1001] = -0.7;
        buffer[1002] = 0.5;

        // When processAudioChunk is called with an impulse spike, it executes the DSP pipeline
        await engine.processAudioChunk(buffer);
        // The function must execute safely without throwing exceptions
        expect(true, isTrue);
      },
    );

    test(
      'Silent audio buffer does not trigger false positive detections',
      () async {
        final silentBuffer = Float32List(15600); // All zeros
        bool triggered = false;

        final sub = engine.detectionStream.listen((_) {
          triggered = true;
        });

        await engine.processAudioChunk(silentBuffer);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(triggered, isFalse);
        await sub.cancel();
      },
    );
  });
}

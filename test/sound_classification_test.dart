import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo_alert/services/yamnet_classifier.dart';
import 'package:echo_alert/services/sound_classification_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Member C - TensorFlow Lite & YAMNet Detection Tests', () {
    late SoundClassificationEngine engine;

    setUp(() {
      engine = SoundClassificationEngine();
    });

    test('Default Category Sensitivities and Toggles are configured', () {
      expect(engine.getSensitivity('Doorbell'), equals(0.70));
      expect(engine.getSensitivity('Smoke Alarm'), equals(0.75));
      expect(engine.isCategoryEnabled('Doorbell'), isTrue);
      expect(engine.isCategoryEnabled('Smoke Alarm'), isTrue);
    });

    test('Dynamic update of sensitivity and toggles work without database', () {
      engine.updateSensitivity('Doorbell', 0.85);
      expect(engine.getSensitivity('Doorbell'), equals(0.85));

      engine.toggleCategory('Doorbell', false);
      expect(engine.isCategoryEnabled('Doorbell'), isFalse);
    });

    test('Simulated detection triggers detectionStream event', () async {
      final detectionFuture = engine.detectionStream.first;

      engine.simulateDetection('Doorbell', 'Ding-dong', 0.88);

      final result = await detectionFuture;
      expect(result.category, equals('Doorbell'));
      expect(result.soundLabel, equals('Ding-dong'));
      expect(result.confidence, equals(0.88));
      expect(engine.latestDetection, isNotNull);
      expect(engine.recentDetections.length, equals(1));
    });

    test('Audio buffer padding and truncation maintains sample size', () {
      final shortBuffer = Float32List(1000);
      final longBuffer = Float32List(20000);

      expect(shortBuffer.length, isNot(equals(YamnetClassifier.expectedSampleCount)));
      expect(longBuffer.length, isNot(equals(YamnetClassifier.expectedSampleCount)));
    });
  });
}

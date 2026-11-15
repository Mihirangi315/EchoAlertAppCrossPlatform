import 'package:flutter_test/flutter_test.dart';
import 'package:echo_alert/models/detection_event.dart';
import 'package:echo_alert/models/sound_setting.dart';

void main() {
  group('Database Models Unit Tests', () {
    test('DetectionEvent serialization and deserialization', () {
      final now = DateTime.now();
      final event = DetectionEvent(
        id: 10,
        soundLabel: 'Smoke / Fire Alarm',
        confidence: 0.965,
        timestamp: now,
      );

      final map = event.toMap();
      expect(map['id'], equals(10));
      expect(map['soundLabel'], equals('Smoke / Fire Alarm'));
      expect(map['confidence'], closeTo(0.965, 0.001));
      expect(map['timestamp'], equals(now.millisecondsSinceEpoch));

      final deserialized = DetectionEvent.fromMap(map);
      expect(deserialized.id, equals(event.id));
      expect(deserialized.soundLabel, equals(event.soundLabel));
      expect(deserialized.confidence, closeTo(event.confidence, 0.001));
      expect(
        deserialized.timestamp.millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );
    });

    test('DetectionEvent serialization with null id handles autoincrement', () {
      final now = DateTime.now();
      final event = DetectionEvent(
        soundLabel: 'Doorbell',
        confidence: 0.88,
        timestamp: now,
      );

      final map = event.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['soundLabel'], equals('Doorbell'));
      expect(map['confidence'], equals(0.88));
    });

    test('SoundSetting serialization and deserialization', () {
      final setting = SoundSetting(
        soundLabel: 'Baby crying',
        isEnabled: true,
        sensitivity: 0.75,
      );

      final map = setting.toMap();
      expect(map['soundLabel'], equals('Baby crying'));
      expect(map['isEnabled'], equals(1));
      expect(map['sensitivity'], equals(0.75));

      final deserialized = SoundSetting.fromMap(map);
      expect(deserialized.soundLabel, equals('Baby crying'));
      expect(deserialized.isEnabled, isTrue);
      expect(deserialized.sensitivity, equals(0.75));
    });

    test('SoundSetting disabled maps isEnabled to 0', () {
      final setting = SoundSetting(
        soundLabel: 'Door knocking',
        isEnabled: false,
        sensitivity: 0.60,
      );

      final map = setting.toMap();
      expect(map['isEnabled'], equals(0));

      final deserialized = SoundSetting.fromMap(map);
      expect(deserialized.isEnabled, isFalse);
    });

    test('kDefaultSounds contains all 5 required target sound categories', () {
      expect(kDefaultSounds.containsKey('Doorbell'), isTrue);
      expect(kDefaultSounds.containsKey('Smoke / Fire Alarm'), isTrue);
      expect(kDefaultSounds.containsKey('Baby crying'), isTrue);
      expect(kDefaultSounds.containsKey('Phone ringing'), isTrue);
      expect(kDefaultSounds.containsKey('Door knocking'), isTrue);

      for (var entry in kDefaultSounds.entries) {
        expect(entry.value, inInclusiveRange(0.50, 0.95));
      }
    });
  });
}

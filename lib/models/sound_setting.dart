
const Map<String, double> kDefaultSounds = {
  'Doorbell': 0.85,
  'Smoke / Fire Alarm': 0.90,
  'Baby crying': 0.80,
  'Phone ringing': 0.85,
  'Door knocking': 0.75,
};

class SoundSetting {
  final String soundLabel;
  bool isEnabled;
  double sensitivity;

  SoundSetting({
    required this.soundLabel,
    this.isEnabled = true,
    this.sensitivity = 0.80,
  });

  Map<String, dynamic> toMap() => {
        'soundLabel': soundLabel,
        'isEnabled': isEnabled ? 1 : 0,
        'sensitivity': sensitivity,
      };

  factory SoundSetting.fromMap(Map<String, dynamic> map) => SoundSetting(
        soundLabel: map['soundLabel'] as String,
        isEnabled: (map['isEnabled'] as int) == 1,
        sensitivity: (map['sensitivity'] as num).toDouble(),
      );
}
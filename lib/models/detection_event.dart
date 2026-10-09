class DetectionEvent {
  final int? id;
  final String soundLabel;
  final double confidence;
  final DateTime timestamp;

  DetectionEvent({
    this.id,
    required this.soundLabel,
    required this.confidence,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'soundLabel': soundLabel,
        'confidence': confidence,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory DetectionEvent.fromMap(Map<String, dynamic> map) => DetectionEvent(
        id: map['id'] as int?,
        soundLabel: map['soundLabel'] as String,
        confidence: (map['confidence'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
}
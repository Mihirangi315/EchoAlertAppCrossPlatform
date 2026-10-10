import 'dart:convert';

/// Represents a detected target sound event from the YAMNet classification engine.
class DetectionResult {
  final String soundLabel;
  final String category;
  final double confidence;
  final int timestamp;

  DetectionResult({
    required this.soundLabel,
    required this.category,
    required this.confidence,
    required this.timestamp,
  });

  /// Factory constructor to build DetectionResult from JSON / Map.
  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      soundLabel: map['soundLabel'] as String,
      category: map['category'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
    );
  }

  /// Converts DetectionResult to Map for SQLite or JSON serialization.
  Map<String, dynamic> toMap() {
    return {
      'soundLabel': soundLabel,
      'category': category,
      'confidence': confidence,
      'timestamp': timestamp,
    };
  }

  String toJson() => json.encode(toMap());

  factory DetectionResult.fromJson(String source) =>
      DetectionResult.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DetectionResult(category: $category, label: $soundLabel, confidence: ${(confidence * 100).toStringAsFixed(1)}%, timestamp: $timestamp)';
  }
}

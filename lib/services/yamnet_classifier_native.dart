import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Class containing sound prediction candidate from YAMNet.
class ClassificationCandidate {
  final String label;
  final String category;
  final double confidence;

  ClassificationCandidate({
    required this.label,
    required this.category,
    required this.confidence,
  });

  @override
  String toString() => '$category ($label): ${(confidence * 100).toStringAsFixed(1)}%';
}

/// Member C: Native YAMNet TFLite Model Classifier (Android / iOS / Desktop)
class YamnetClassifier {
  static const String modelAssetPath = 'assets/models/yamnet.tflite';
  static const String labelsAssetPath = 'assets/models/yamnet_label_list.txt';

  static const int expectedSampleCount = 15600;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static final Map<String, List<String>> targetCategoryMappings = {
    'Doorbell': ['doorbell', 'ding-dong', 'chime', 'bell'],
    'Smoke Alarm': ['smoke detector, smoke alarm', 'fire alarm', 'siren', 'alarm', 'civil defense siren', 'alarm clock', 'buzzer'],
    'Baby Crying': ['crying, sobbing', 'baby cry, infant cry', 'tears', 'baby laughter'],
    'Phone Ringing': ['telephone', 'ringtone', 'cell phone', 'telephone bell ringing'],
    'Door Knocking': ['knock', 'tap', 'door'],
  };

  final Map<int, String> _labelIndexToCategory = {};

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final labelsData = await rootBundle.loadString(labelsAssetPath);
      _labels = labelsData
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      _buildCategoryLookupMap();

      try {
        final options = InterpreterOptions()..threads = 2;
        _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);
      } catch (e) {
        debugPrint('YamnetClassifier: TFLite model asset not found or platform unsupported ($e).');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('YamnetClassifier initialization error: $e');
      return false;
    }
  }

  void _buildCategoryLookupMap() {
    _labelIndexToCategory.clear();
    for (int i = 0; i < _labels.length; i++) {
      final labelLower = _labels[i].toLowerCase();
      for (var entry in targetCategoryMappings.entries) {
        final category = entry.key;
        final keywords = entry.value;
        for (var kw in keywords) {
          if (labelLower == kw.toLowerCase() || labelLower.contains(kw.toLowerCase())) {
            _labelIndexToCategory[i] = category;
            break;
          }
        }
      }
    }
  }

  Future<List<ClassificationCandidate>> classifyAudioBuffer(Float32List audioBuffer) async {
    if (!_isInitialized) {
      await initialize();
    }

    final stopwatch = Stopwatch()..start();
    List<ClassificationCandidate> candidates = [];

    final Float32List processedInput = _padOrTruncateBuffer(audioBuffer, expectedSampleCount);

    if (_interpreter != null) {
      try {
        var input = [processedInput];
        var output = List.filled(1 * 521, 0.0).reshape([1, 521]);

        _interpreter!.run(input, output);

        List<double> scores = List<double>.from(output[0]);

        for (int i = 0; i < scores.length; i++) {
          final score = scores[i];
          if (_labelIndexToCategory.containsKey(i)) {
            final category = _labelIndexToCategory[i]!;
            final label = i < _labels.length ? _labels[i] : 'Unknown';
            candidates.add(ClassificationCandidate(
              label: label,
              category: category,
              confidence: score,
            ));
          }
        }
      } catch (e) {
        debugPrint('YamnetClassifier native inference error: $e');
      }
    } else {
      candidates = _simulateInference(processedInput);
    }

    stopwatch.stop();
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates;
  }

  Float32List _padOrTruncateBuffer(Float32List input, int targetSize) {
    if (input.length == targetSize) return input;
    final result = Float32List(targetSize);
    if (input.length > targetSize) {
      result.setRange(0, targetSize, input);
    } else {
      result.setRange(0, input.length, input);
    }
    return result;
  }

  List<ClassificationCandidate> _simulateInference(Float32List audioBuffer) {
    double sumSq = 0.0;
    for (int i = 0; i < audioBuffer.length; i++) {
      sumSq += audioBuffer[i] * audioBuffer[i];
    }
    double rms = audioBuffer.isNotEmpty ? (sumSq / audioBuffer.length) : 0.0;

    if (rms < 0.01) return [];

    return [
      ClassificationCandidate(
        label: 'Doorbell',
        category: 'Doorbell',
        confidence: (rms * 5.0).clamp(0.0, 0.95),
      ),
    ];
  }

  String? getCategoryForIndex(int index) => _labelIndexToCategory[index];

  void close() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

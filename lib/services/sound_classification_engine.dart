import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/detection_result.dart';
import 'yamnet_classifier.dart';
import 'audio_service.dart';

/// Member C: Sound Classification Engine
/// High-performance audio classification pipeline that receives live PCM audio buffers,
/// runs YAMNet inference via [YamnetClassifier], applies sensitivity filtering,
/// and broadcasts detected sound events via [detectionStream].
class SoundClassificationEngine extends ChangeNotifier {
  static final SoundClassificationEngine _instance =
      SoundClassificationEngine._internal();
  factory SoundClassificationEngine() => _instance;
  SoundClassificationEngine._internal();

  final YamnetClassifier _classifier = YamnetClassifier();
  StreamSubscription<Float32List>? _audioSubscription;

  final _detectionController = StreamController<DetectionResult>.broadcast();

  /// Broadcast stream emitting target sound detections in real time
  Stream<DetectionResult> get detectionStream => _detectionController.stream;

  /// Recent detections log for UI display
  final List<DetectionResult> _recentDetections = [];
  List<DetectionResult> get recentDetections => List.unmodifiable(_recentDetections);

  /// Current live detection state for Member A's Live Detection View
  DetectionResult? _latestDetection;
  DetectionResult? get latestDetection => _latestDetection;

  /// Default sensitivity thresholds — lowered to 0.60-0.65 to work with
  /// DSP-based confidence scores from yamnet_classifier_web.dart.
  /// These can be updated dynamically from the Settings screen.
  final Map<String, double> _sensitivityThresholds = {
    'Doorbell':      0.63,
    'Smoke Alarm':   0.65,
    'Baby Crying':   0.62,
    'Phone Ringing': 0.63,
    'Door Knocking': 0.60,
  };

  final Map<String, bool> _enabledCategories = {
    'Doorbell': true,
    'Smoke Alarm': true,
    'Baby Crying': true,
    'Phone Ringing': true,
    'Door Knocking': true,
  };

  bool _isEngineRunning = false;
  bool get isEngineRunning => _isEngineRunning;

  /// Initialize ML classifier model and label mapping
  Future<bool> initialize() async {
    return await _classifier.initialize();
  }

  /// Start continuous audio classification pipeline by listening to AudioService stream
  Future<void> startEngine() async {
    if (_isEngineRunning) return;

    final initialized = await initialize();
    if (!initialized) {
      debugPrint('SoundClassificationEngine: Failed to initialize YamnetClassifier');
      return;
    }

    _isEngineRunning = true;
    notifyListeners();

    // Subscribe to continuous audio stream from Member B's AudioService
    _audioSubscription?.cancel();
    _audioSubscription = AudioService().audioStream.listen(
      (Float32List audioBuffer) {
        processAudioChunk(audioBuffer);
      },
      onError: (error) {
        debugPrint('SoundClassificationEngine Audio Stream Error: $error');
      },
    );

    debugPrint('SoundClassificationEngine: Engine started successfully');
  }

  /// Stop audio classification pipeline
  Future<void> stopEngine() async {
    if (!_isEngineRunning) return;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _isEngineRunning = false;
    notifyListeners();
    debugPrint('SoundClassificationEngine: Engine stopped');
  }

  /// Process a single 15,600 PCM Float32List audio chunk (0.975s @ 16kHz)
  Future<void> processAudioChunk(Float32List audioChunk) async {
    if (!_isEngineRunning && !kDebugMode) return;

    final stopwatch = Stopwatch()..start();

    // 1. Run YAMNet TFLite inference
    final candidates = await _classifier.classifyAudioBuffer(audioChunk);

    stopwatch.stop();
    final inferenceTimeMs = stopwatch.elapsedMilliseconds;

    // 2. Filter predictions against active target categories & sensitivity thresholds
    for (var candidate in candidates) {
      final category = candidate.category;
      final confidence = candidate.confidence;

      final isEnabled = _enabledCategories[category] ?? true;
      final threshold = _sensitivityThresholds[category] ?? 0.70;

      if (isEnabled && confidence >= threshold) {
        final detection = DetectionResult(
          soundLabel: candidate.label,
          category: category,
          confidence: confidence,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        _handleDetectionTriggered(detection, inferenceTimeMs);
        // Only trigger primary detection per audio chunk
        break;
      }
    }
  }

  void _handleDetectionTriggered(DetectionResult detection, int inferenceTimeMs) {
    debugPrint('🎉 Sound Detected! ${detection.category} (${(detection.confidence * 100).toStringAsFixed(1)}%) in ${inferenceTimeMs}ms');

    _latestDetection = detection;
    _recentDetections.insert(0, detection);
    if (_recentDetections.length > 50) {
      _recentDetections.removeLast();
    }

    // Broadcast detection result event
    _detectionController.add(detection);
    notifyListeners();
  }

  /// Dynamic update of target sound sensitivity threshold (e.g. from Settings screen or DB)
  void updateSensitivity(String category, double threshold) {
    _sensitivityThresholds[category] = threshold.clamp(0.50, 0.95);
    notifyListeners();
    debugPrint('SoundClassificationEngine: Updated $category sensitivity threshold to ${threshold.toStringAsFixed(2)}');
  }

  /// Dynamic toggle of target category monitoring state
  void toggleCategory(String category, bool isEnabled) {
    _enabledCategories[category] = isEnabled;
    notifyListeners();
    debugPrint('SoundClassificationEngine: Toggled $category monitoring to $isEnabled');
  }

  /// Get current sensitivity threshold for a category
  double getSensitivity(String category) {
    return _sensitivityThresholds[category] ?? 0.70;
  }

  /// Get monitoring enabled state for a category
  bool isCategoryEnabled(String category) {
    return _enabledCategories[category] ?? true;
  }

  /// Test helper to simulate a sound detection (for Member E testing or manual UI testing)
  void simulateDetection(String category, String label, double confidence) {
    final detection = DetectionResult(
      soundLabel: label,
      category: category,
      confidence: confidence,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _handleDetectionTriggered(detection, 15);
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _detectionController.close();
    _classifier.close();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'permission_manager.dart';

/// AudioService handles continuous microphone capture via native Android Foreground Service.
/// Exposes a stream of 15,600 PCM Float32List audio chunks for YAMNet TFLite inference.
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const MethodChannel _controlChannel =
      MethodChannel('com.example.echo_alert/audio_control');
  static const EventChannel _streamChannel =
      EventChannel('com.example.echo_alert/audio_stream');

  bool _isListening = false;
  bool get isListening => _isListening;

  StreamSubscription? _audioSubscription;
  final _audioStreamController = StreamController<Float32List>.broadcast();

  /// Stream of 16kHz PCM Float32List samples (0.975s / 15,600 samples)
  Stream<Float32List> get audioStream => _audioStreamController.stream;

  /// Start the audio foreground service and begin listening.
  Future<bool> startListening() async {
    if (_isListening) return true;

    // 1. Request microphone & notification permissions
    final hasPermission = await PermissionManager.requestAudioPermissions();
    if (!hasPermission) {
      debugPrint('AudioService: Permission denied by user');
      return false;
    }

    try {
      // 2. Start native foreground service
      final bool started = await _controlChannel.invokeMethod('startListening');
      if (started) {
        _isListening = true;
        _subscribeToAudioStream();
        notifyListeners();
        debugPrint('AudioService: Started listening successfully');
        return true;
      }
    } catch (e) {
      debugPrint('AudioService: Failed to start listening service: $e');
    }
    return false;
  }

  /// Stop the audio foreground service.
  Future<bool> stopListening() async {
    if (!_isListening) return true;

    try {
      final bool stopped = await _controlChannel.invokeMethod('stopListening');
      if (stopped) {
        _isListening = false;
        await _unsubscribeFromAudioStream();
        notifyListeners();
        debugPrint('AudioService: Stopped listening service');
        return true;
      }
    } catch (e) {
      debugPrint('AudioService: Failed to stop listening service: $e');
    }
    return false;
  }

  void _subscribeToAudioStream() {
    _audioSubscription?.cancel();
    _audioSubscription = _streamChannel.receiveBroadcastStream().listen(
      (dynamic data) {
        if (data is List) {
          final floats = Float32List.fromList(
            data.map((e) => (e as num).toDouble()).toList(),
          );
          _audioStreamController.add(floats);
        }
      },
      onError: (error) {
        debugPrint('AudioService Stream Error: $error');
      },
    );
  }

  Future<void> _unsubscribeFromAudioStream() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _audioStreamController.close();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'permission_manager.dart';

/// Member B: Native Audio Service for Android / iOS / Desktop
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

  Stream<Float32List> get audioStream => _audioStreamController.stream;

  Future<bool> startListening() async {
    if (_isListening) return true;

    final hasPermission = await PermissionManager.requestAudioPermissions();
    if (!hasPermission) {
      debugPrint('AudioService (Native): Permission denied by user');
      return false;
    }

    try {
      final bool started = await _controlChannel.invokeMethod('startListening');
      if (started) {
        _isListening = true;
        _subscribeToAudioStream();
        notifyListeners();
        debugPrint('AudioService (Native): Native listening service started');
        return true;
      }
    } catch (e) {
      debugPrint('AudioService (Native): Native service error ($e).');
    }
    return false;
  }

  Future<bool> stopListening() async {
    if (!_isListening) return true;

    try {
      await _controlChannel.invokeMethod('stopListening');
      await _unsubscribeFromAudioStream();
    } catch (e) {
      debugPrint('AudioService (Native) stop error: $e');
    }

    _isListening = false;
    notifyListeners();
    debugPrint('AudioService (Native): Service stopped');
    return true;
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

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Member B: Web Audio Service — Real HTML5 Microphone Stream
///
/// Uses the modern dart:js_interop + package:web APIs (Flutter 3.19+)
/// instead of the deprecated dart:js_util approach.
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  web.MediaStream? _mediaStream;
  web.AudioContext? _audioContext;
  web.ScriptProcessorNode? _scriptProcessor;
  web.MediaStreamAudioSourceNode? _sourceNode;

  final _audioStreamController = StreamController<Float32List>.broadcast();
  Stream<Float32List> get audioStream => _audioStreamController.stream;

  final List<double> _sampleBuffer = [];
  static const int chunkSize = 15600; // 0.975 seconds @ 16kHz

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Start live microphone streaming via Web Audio API.
  /// This triggers the browser's "Allow microphone?" permission dialog.
  Future<bool> startListening() async {
    if (_isListening) return true;

    try {
      // 1. Request microphone permission from browser
      _mediaStream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;

      debugPrint('AudioService (Web): Browser microphone permission granted!');

      // 2. Create AudioContext at 16kHz for YAMNet compatibility
      final options = web.AudioContextOptions();
      options.sampleRate = 16000.0;
      _audioContext = web.AudioContext(options);

      // 3. Wire: MediaStream → ScriptProcessor → destination (captures PCM)
      _sourceNode = _audioContext!.createMediaStreamSource(_mediaStream!);
      // bufferSize=4096, inputChannels=1, outputChannels=1
      _scriptProcessor =
          _audioContext!.createScriptProcessor(4096, 1, 1);

      // 4. Intercept PCM frames in the onaudioprocess callback
      _scriptProcessor!.onaudioprocess = (web.AudioProcessingEvent e) {
        if (!_isListening) return;

        final inputBuffer = e.inputBuffer;
        // getChannelData returns JSFloat32Array — convert to Dart Float32List
        final jsChannelData = inputBuffer.getChannelData(0);
        final Float32List channelData = jsChannelData.toDart;

        // Accumulate samples into chunk buffer
        for (int i = 0; i < channelData.length; i++) {
          _sampleBuffer.add(channelData[i].toDouble());
          if (_sampleBuffer.length >= chunkSize) {
            final chunk =
                Float32List.fromList(_sampleBuffer.sublist(0, chunkSize));
            _sampleBuffer.removeRange(0, chunkSize);
            _audioStreamController.add(chunk);
          }
        }
      }.toJS;

      _sourceNode!.connect(_scriptProcessor!);
      _scriptProcessor!.connect(_audioContext!.destination);

      _isListening = true;
      notifyListeners();
      debugPrint('AudioService (Web): Live microphone stream active');
      return true;
    } catch (e) {
      debugPrint('AudioService (Web): Microphone start error — $e');
      _isListening = false;
      notifyListeners();
      return false;
    }
  }

  /// Stop browser microphone capture and release resources.
  Future<bool> stopListening() async {
    if (!_isListening) return true;

    try {
      _sourceNode?.disconnect();
      _scriptProcessor?.disconnect();
      _mediaStream?.getTracks().toDart.forEach((t) => t.stop());
      _audioContext?.close();
    } catch (e) {
      debugPrint('AudioService (Web): Stop error — $e');
    }

    _mediaStream = null;
    _audioContext = null;
    _scriptProcessor = null;
    _sourceNode = null;
    _sampleBuffer.clear();

    _isListening = false;
    notifyListeners();
    debugPrint('AudioService (Web): Microphone stopped');
    return true;
  }

  @override
  void dispose() {
    stopListening();
    _audioStreamController.close();
    super.dispose();
  }
}

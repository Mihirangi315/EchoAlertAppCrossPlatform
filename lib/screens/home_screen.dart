import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/sound_classification_engine.dart';
import '../services/permission_manager.dart';
import '../models/detection_result.dart';
import 'alert_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  DetectionResult? _lastDetectedEvent;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to real-time ML detection stream
    SoundClassificationEngine().detectionStream.listen((detection) {
      if (mounted) {
        setState(() {
          _lastDetectedEvent = detection;
        });
        _triggerAlertOverlay(detection.category, detection.confidence);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      // ✅ FIX 1: Request microphone permission BEFORE starting audio
      final permissionGranted = await PermissionManager.requestAudioPermissions();
      if (!permissionGranted) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return;
      }

      await SoundClassificationEngine().startEngine();
      final bool success = await AudioService().startListening();
      if (success) {
        setState(() {
          _isListening = true;
          _pulseController.repeat(reverse: true);
        });
      } else {
        await SoundClassificationEngine().stopEngine();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to access microphone. Please allow microphone permission.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      await AudioService().stopListening();
      await SoundClassificationEngine().stopEngine();
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.reset();
      });
    }
  }

  /// Show dialog when microphone permission is denied
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic_off, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Microphone Permission Required'),
          ],
        ),
        content: const Text(
          'EchoAlert needs microphone access to detect sounds.\n\n'
          'Please grant microphone permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await PermissionManager.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _simulateDetection() {
    // ✅ FIX 2: Use correct category name matching engine's category map
    SoundClassificationEngine().simulateDetection(
      'Smoke Alarm',
      'Smoke detector, smoke alarm',
      0.94,
    );
  }

  void _triggerAlertOverlay(String soundCategory, double confidence) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertOverlay(
        detectedSound: soundCategory,
        confidence: confidence,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EchoAlert'),
        actions: [
          if (_isListening)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                avatar: const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 14),
                label: const Text('LIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.redAccent.withOpacity(0.15),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status text
            Text(
              _isListening ? 'Listening for sounds...' : 'Tap to start listening',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: _isListening ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
            if (_lastDetectedEvent != null) ...[
              const SizedBox(height: 12),
              Chip(
                avatar: const Icon(Icons.graphic_eq, size: 18),
                label: Text(
                  'Last: ${_lastDetectedEvent!.category} (${(_lastDetectedEvent!.confidence * 100).toStringAsFixed(0)}%)',
                  style: theme.textTheme.bodyMedium,
                ),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
            ],
            const SizedBox(height: 40),

            // Main listening toggle button
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceVariant,
                        boxShadow: [
                          if (_isListening)
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 10,
                            ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.hearing : Icons.mic_off,
                        size: 80,
                        color: _isListening
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 60),

            // Simulation button for testing
            if (_isListening)
              ElevatedButton.icon(
                onPressed: _simulateDetection,
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Simulate Detection'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onError,
                  backgroundColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

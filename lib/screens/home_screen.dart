import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/sound_classification_engine.dart';
import '../services/permission_manager.dart';
import '../database/app_database.dart';
import '../models/detection_result.dart';
import 'alert_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  DetectionResult? _lastDetectedEvent;
  int _todayAlertsCount = 0;
  int _activeCategoriesCount = 5;

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

    _loadStats();

    // Listen to real-time ML detection stream
    SoundClassificationEngine().detectionStream.listen((detection) {
      if (mounted) {
        setState(() {
          _lastDetectedEvent = detection;
          _todayAlertsCount++;
        });
        _triggerAlertOverlay(detection.category, detection.confidence);
      }
    });
  }

  Future<void> _loadStats() async {
    try {
      final events = await AppDatabase.instance.getEvents();
      final now = DateTime.now();
      final todayCount = events.where((e) {
        return e.timestamp.year == now.year &&
            e.timestamp.month == now.month &&
            e.timestamp.day == now.day;
      }).length;

      final settings = await AppDatabase.instance.getSettings();
      final activeCount = settings.where((s) => s.isEnabled).length;

      if (mounted) {
        setState(() {
          _todayAlertsCount = todayCount;
          _activeCategoriesCount = activeCount;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen: Error loading stats: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      // 1. Check & request microphone permission with graceful rationale dialog
      final permissionGranted =
          await PermissionManager.requestAudioPermissions();
      if (!permissionGranted) {
        if (mounted) {
          await PermissionManager.showMicrophoneRationaleDialog(
            context,
            onRetry: _toggleListening,
          );
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
              content: Text(
                'Failed to access microphone. Please check system permissions.',
              ),
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

  void _simulateDetection() {
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
      builder: (context) =>
          AlertOverlay(detectedSound: soundCategory, confidence: confidence),
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
              padding: const EdgeInsets.only(right: 12.0),
              child: Chip(
                avatar: const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.redAccent,
                  size: 14,
                ),
                label: const Text(
                  'LISTENING',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.redAccent.withOpacity(0.15),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'Alerts Today',
                      value: '$_todayAlertsCount',
                      icon: Icons.notifications_active_outlined,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      theme,
                      title: 'Monitored Sounds',
                      value: '$_activeCategoriesCount of 5',
                      icon: Icons.check_circle_outline,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Status text when listening is active
              if (_isListening) ...[
                Text(
                  'EchoAlert is Actively Listening',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitoring ambient audio for safety & critical sounds',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              if (_lastDetectedEvent != null) ...[
                const SizedBox(height: 16),
                Chip(
                  avatar: const Icon(Icons.graphic_eq, size: 18),
                  label: Text(
                    'Last Detected: ${_lastDetectedEvent!.category} (${(_lastDetectedEvent!.confidence * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ],

              const SizedBox(height: 36),

              // Hero listening toggle button
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceVariant,
                          boxShadow: [
                            if (_isListening)
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.35,
                                ),
                                blurRadius: 28,
                                spreadRadius: 10,
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isListening ? Icons.hearing : Icons.mic_off,
                              size: 64,
                              color: _isListening
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isListening ? 'STOP' : 'START',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: _isListening
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Explicit Start / Stop Labeled Button
              FilledButton.icon(
                onPressed: _toggleListening,
                icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _isListening ? 'STOP LISTENING' : 'START LISTENING',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _isListening
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  foregroundColor: _isListening
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),

              const SizedBox(height: 40),

              // Simulation button for testing
              if (_isListening)
                ElevatedButton.icon(
                  onPressed: _simulateDetection,
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Simulate Test Alert'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onError,
                    backgroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

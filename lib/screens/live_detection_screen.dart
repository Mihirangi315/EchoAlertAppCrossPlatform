import 'dart:async';

import 'package:flutter/material.dart';

import '../models/detection_result.dart';
import '../services/sound_classification_engine.dart';
import '../services/audio_service.dart';

/// Member A: Live Detection Screen
///
/// Displays real-time audio visualization, current detected sound with confidence,
/// and live rolling classification history feed.
class LiveDetectionScreen extends StatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen>
    with SingleTickerProviderStateMixin {
  final SoundClassificationEngine _engine = SoundClassificationEngine();
  final AudioService _audioService = AudioService();
  StreamSubscription<DetectionResult>? _detectionSubscription;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _detectionSubscription = _engine.detectionStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _detectionSubscription?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'doorbell':
        return Icons.doorbell;
      case 'smoke alarm':
      case 'smoke / fire alarm':
        return Icons.warning_amber_rounded;
      case 'baby crying':
        return Icons.child_care;
      case 'phone ringing':
        return Icons.phone_in_talk;
      case 'door knocking':
        return Icons.back_hand;
      default:
        return Icons.graphic_eq;
    }
  }

  Color _getColorForCategory(String category, BuildContext context) {
    final theme = Theme.of(context);
    switch (category.toLowerCase()) {
      case 'smoke alarm':
      case 'smoke / fire alarm':
        return Colors.redAccent;
      case 'baby crying':
        return Colors.purpleAccent;
      case 'doorbell':
        return Colors.amber.shade700;
      case 'phone ringing':
        return Colors.teal;
      case 'door knocking':
        return Colors.blueAccent;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isListening = _audioService.isListening || _engine.isEngineRunning;
    final latest = _engine.latestDetection;
    final recentList = _engine.recentDetections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Detection'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isListening
                  ? Colors.greenAccent.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: isListening ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  isListening ? 'LISTENING' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isListening ? Colors.green.shade800 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Audio Waveform / Visualizer Level Meter
          _buildWaveformVisualizer(theme, isListening),

          const SizedBox(height: 16),

          // 2. Currently Detected Sound Hero Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildCurrentDetectionCard(theme, latest, isListening),
          ),

          const SizedBox(height: 16),

          // 3. Rolling Live Feed Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Detections Feed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${recentList.length} events',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Rolling List of Recent Classifications
          Expanded(
            child: recentList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hearing_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isListening
                              ? 'Waiting for ambient sounds...'
                              : 'Listening is stopped. Start from Home.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: recentList.length,
                    itemBuilder: (context, index) {
                      final item = recentList[index];
                      final color = _getColorForCategory(
                        item.category,
                        context,
                      );
                      final timeStr = _formatTimestamp(item.timestamp);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(
                              _getIconForCategory(item.category),
                              color: color,
                            ),
                          ),
                          title: Text(
                            item.category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Mapped class: ${item.soundLabel}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(item.confidence * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              Text(timeStr, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformVisualizer(ThemeData theme, bool isListening) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 70,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(24, (i) {
                final heightFactor = isListening
                    ? (0.2 +
                          (0.8 *
                              (((i + 1) * 0.17 + _waveController.value) % 1.0)))
                    : 0.15;
                return Container(
                  width: 4,
                  height: 48 * heightFactor,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isListening
                        ? theme.colorScheme.primary.withOpacity(
                            0.7 + (0.3 * heightFactor),
                          )
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentDetectionCard(
    ThemeData theme,
    DetectionResult? latest,
    bool isListening,
  ) {
    if (latest == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.surfaceVariant,
                child: Icon(
                  isListening ? Icons.graphic_eq : Icons.mic_off,
                  size: 30,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Active Sound Detected',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isListening
                          ? 'Monitoring 16kHz audio stream...'
                          : 'Microphone listening is paused.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = _getColorForCategory(latest.category, context);

    return Card(
      elevation: 3,
      color: color.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.6), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Icon(
                _getIconForCategory(latest.category),
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latest.category,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Label: ${latest.soundLabel}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: latest.confidence,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(latest.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final hours = dt.hour.toString().padLeft(2, '0');
    final minutes = dt.minute.toString().padLeft(2, '0');
    final seconds = dt.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

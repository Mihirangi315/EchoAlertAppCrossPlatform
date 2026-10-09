import 'package:flutter/material.dart';

// Temporary mock data model until database is integrated
class DetectionEvent {
  final String soundLabel;
  final double confidence;
  final DateTime timestamp;

  DetectionEvent({
    required this.soundLabel,
    required this.confidence,
    required this.timestamp,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Mock history list
  final List<DetectionEvent> _mockHistory = [
    DetectionEvent(
      soundLabel: 'Doorbell',
      confidence: 0.89,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    DetectionEvent(
      soundLabel: 'Baby crying',
      confidence: 0.95,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    DetectionEvent(
      soundLabel: 'Smoke / Fire Alarm',
      confidence: 0.99,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconForSound(String label) {
    switch (label.toLowerCase()) {
      case 'doorbell':
        return Icons.doorbell;
      case 'smoke / fire alarm':
      case 'smoke alarm':
        return Icons.warning_amber;
      case 'baby crying':
        return Icons.child_care;
      case 'phone ringing':
        return Icons.phone_in_talk;
      case 'door knocking':
        return Icons.back_hand;
      default:
        return Icons.notifications_active;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Clear history from DB
            },
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: _mockHistory.isEmpty
          ? const Center(
              child: Text('No detection events yet.'),
            )
          : ListView.builder(
              itemCount: _mockHistory.length,
              itemBuilder: (context, index) {
                final event = _mockHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        _getIconForSound(event.soundLabel),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      event.soundLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Confidence: ${(event.confidence * 100).toStringAsFixed(1)}%',
                    ),
                    trailing: Text(
                      _formatTime(event.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/detection_event.dart';

/// Member A & Member D Integration: History Screen
///
/// Chronological audit log of all detected sound events retrieved from SQLite database.
/// Supports category filtering, text search, pull-to-refresh, swipe-to-delete, and clearing history.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DetectionEvent> _allEvents = [];
  List<DetectionEvent> _filteredEvents = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Doorbell',
    'Smoke / Fire Alarm',
    'Baby crying',
    'Phone ringing',
    'Door knocking',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    if (kIsWeb) {
      // Web fallback mock data
      _allEvents = [
        DetectionEvent(
          id: 1,
          soundLabel: 'Doorbell',
          confidence: 0.89,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        DetectionEvent(
          id: 2,
          soundLabel: 'Baby crying',
          confidence: 0.95,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        DetectionEvent(
          id: 3,
          soundLabel: 'Smoke / Fire Alarm',
          confidence: 0.99,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      _applyFilter();
      setState(() => _isLoading = false);
      return;
    }

    try {
      final events = await AppDatabase.instance.getEvents();
      _allEvents = events;
      _applyFilter();
    } catch (e) {
      debugPrint('HistoryScreen: Error loading events: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    List<DetectionEvent> list = _allEvents;

    if (_selectedCategory != 'All') {
      list = list
          .where((e) => _matchesCategory(e.soundLabel, _selectedCategory))
          .toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) => e.soundLabel.toLowerCase().contains(q)).toList();
    }

    _filteredEvents = list;
  }

  bool _matchesCategory(String soundLabel, String category) {
    final sl = soundLabel.toLowerCase();
    final c = category.toLowerCase();
    if (c.contains('smoke') || c.contains('fire')) {
      return sl.contains('smoke') || sl.contains('fire');
    }
    return sl.contains(c);
  }

  Future<void> _deleteEvent(DetectionEvent event) async {
    if (event.id != null && !kIsWeb) {
      await AppDatabase.instance.deleteEvent(event.id!);
    }
    setState(() {
      _allEvents.removeWhere((e) => e.id == event.id);
      _applyFilter();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${event.soundLabel}" event'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all recorded sound detection events from your device database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!kIsWeb) {
        await AppDatabase.instance.clearHistory();
      }
      setState(() {
        _allEvents.clear();
        _filteredEvents.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Detection history cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

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

  Color _getColorForSound(String label, BuildContext context) {
    final l = label.toLowerCase();
    if (l.contains('smoke') || l.contains('fire')) return Colors.redAccent;
    if (l.contains('baby')) return Colors.purpleAccent;
    if (l.contains('doorbell')) return Colors.amber.shade700;
    if (l.contains('phone')) return Colors.teal;
    if (l.contains('knock')) return Colors.blueAccent;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Log'),
        actions: [
          if (_allEvents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear History',
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search detection history...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilter();
                          });
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilter();
                });
              },
            ),
          ),

          // 2. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? cat : 'All';
                        _applyFilter();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // 3. Event List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                ? RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedCategory != 'All'
                                    ? 'No matching detection events'
                                    : 'No detection events yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Detections will appear here when ambient sounds occur.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: ListView.builder(
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        final color = _getColorForSound(
                          event.soundLabel,
                          context,
                        );

                        return Dismissible(
                          key: ValueKey(
                            event.id ??
                                '${event.soundLabel}_${event.timestamp}',
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _deleteEvent(event),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            elevation: 1,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(
                                  _getIconForSound(event.soundLabel),
                                  color: color,
                                ),
                              ),
                              title: Text(
                                event.soundLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Confidence: ${(event.confidence * 100).toStringAsFixed(1)}%  •  ${_formatDate(event.timestamp)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTime(event.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

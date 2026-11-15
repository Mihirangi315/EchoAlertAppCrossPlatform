import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/sound_setting.dart';
import '../services/alert_manager.dart';
import '../services/detection_bridge.dart';
import '../services/permission_manager.dart';

/// Member A & Member D Integration: Settings Screen
///
/// Configures monitored sound categories and individual sensitivity thresholds.
/// Persists all changes to SQLite database and syncs with SoundClassificationEngine.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<SoundSetting> _settings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    if (kIsWeb) {
      // In web mode, load from defaults
      _settings = kDefaultSounds.entries
          .map((e) => SoundSetting(soundLabel: e.key, sensitivity: e.value))
          .toList();
      setState(() => _isLoading = false);
      return;
    }

    try {
      final dbSettings = await AppDatabase.instance.getSettings();
      if (dbSettings.isNotEmpty) {
        _settings = dbSettings;
      } else {
        _settings = kDefaultSounds.entries
            .map((e) => SoundSetting(soundLabel: e.key, sensitivity: e.value))
            .toList();
      }
    } catch (e) {
      debugPrint('SettingsScreen: Error loading settings: $e');
      _settings = kDefaultSounds.entries
          .map((e) => SoundSetting(soundLabel: e.key, sensitivity: e.value))
          .toList();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onToggleCategory(SoundSetting setting, bool value) async {
    setState(() {
      setting.isEnabled = value;
    });

    if (!kIsWeb) {
      await AppDatabase.instance.updateSetting(setting);
      await DetectionBridge.instance.syncSettings();
    }
  }

  Future<void> _onSensitivityChanged(SoundSetting setting, double value) async {
    setState(() {
      setting.sensitivity = double.parse(value.toStringAsFixed(2));
    });

    if (!kIsWeb) {
      await AppDatabase.instance.updateSetting(setting);
      await DetectionBridge.instance.syncSettings();
    }
  }

  IconData _getIconForSound(String label) {
    switch (label.toLowerCase()) {
      case 'doorbell':
        return Icons.doorbell;
      case 'smoke / fire alarm':
      case 'smoke alarm':
        return Icons.warning_amber_rounded;
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'EchoAlert',
      applicationVersion: '1.0.0 (INTE 22283)',
      applicationIcon: const CircleAvatar(
        radius: 24,
        child: Icon(Icons.hearing, size: 28),
      ),
      children: const [
        Text(
          'EchoAlert is an accessible, real-time sound detection mobile application '
          'designed for individuals who are deaf or hard of hearing.\n\n'
          'Features:\n'
          '• On-device ML classification (YAMNet via TFLite)\n'
          '• Foreground service audio streaming (16kHz PCM)\n'
          '• Distinct haptic vibration alerts & high-priority notifications\n'
          '• Local SQLite persistence (Room entity equivalent)\n'
          '• Developed for Mobile Applications Development (INTE 22283).',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Monitored Sound Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Enable or disable detection categories and adjust confidence sensitivity thresholds.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),

                ..._settings.map((setting) => _buildSettingCard(setting)),

                const Divider(height: 32),

                // Permissions & Testing Section
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    'Permissions & Diagnostics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Test Notification & Vibration'),
                  subtitle: const Text(
                    'Trigger a high-priority test alert for Smoke Alarm',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await AlertManager.instance.showTestAlert(
                        'Smoke / Fire Alarm',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Test alert triggered (vibration & notification)',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('Test'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Microphone Permissions'),
                  subtitle: const Text('Review or change runtime permissions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await PermissionManager.openAppSettings();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About EchoAlert'),
                  subtitle: const Text('Project details, version & team info'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSettingCard(SoundSetting setting) {
    final theme = Theme.of(context);
    final icon = _getIconForSound(setting.soundLabel);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: setting.isEnabled
                      ? theme.colorScheme.primaryContainer
                      : Colors.grey.withOpacity(0.2),
                  child: Icon(
                    icon,
                    size: 22,
                    color: setting.isEnabled
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    setting.soundLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: setting.isEnabled ? null : Colors.grey,
                    ),
                  ),
                ),
                Switch(
                  value: setting.isEnabled,
                  onChanged: (value) => _onToggleCategory(setting, value),
                ),
              ],
            ),
            if (setting.isEnabled) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sensitivity: ${(setting.sensitivity * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.play_arrow_outlined, size: 16),
                    label: const Text(
                      'Test Alert',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      await AlertManager.instance.showTestAlert(
                        setting.soundLabel,
                      );
                    },
                  ),
                ],
              ),
              Slider(
                value: setting.sensitivity,
                min: 0.50,
                max: 0.95,
                divisions: 9,
                label: '${(setting.sensitivity * 100).toInt()}%',
                onChanged: (value) => _onSensitivityChanged(setting, value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

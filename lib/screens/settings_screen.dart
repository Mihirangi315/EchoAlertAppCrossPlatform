import 'package:flutter/material.dart';

// Temporary mock data model until database is integrated
class SoundSetting {
  final String soundLabel;
  bool isEnabled;
  double sensitivity;

  SoundSetting({
    required this.soundLabel,
    this.isEnabled = true,
    this.sensitivity = 0.80,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock settings list
  final List<SoundSetting> _settings = [
    SoundSetting(soundLabel: 'Doorbell', sensitivity: 0.85),
    SoundSetting(soundLabel: 'Smoke / Fire Alarm', sensitivity: 0.90),
    SoundSetting(soundLabel: 'Baby crying', sensitivity: 0.80),
    SoundSetting(soundLabel: 'Phone ringing', sensitivity: 0.85),
    SoundSetting(soundLabel: 'Door knocking', sensitivity: 0.75),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Monitored Sounds',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._settings.map((setting) => _buildSettingCard(setting)).toList(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About EchoAlert'),
            onTap: () {
              // TODO: Show about dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(SoundSetting setting) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  setting.soundLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: setting.isEnabled,
                  onChanged: (value) {
                    setState(() {
                      setting.isEnabled = value;
                      // TODO: Save setting to database
                    });
                  },
                ),
              ],
            ),
            if (setting.isEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Sensitivity: ${(setting.sensitivity * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Slider(
                    value: setting.sensitivity,
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        setting.sensitivity = value;
                        // TODO: Update setting in database
                      });
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

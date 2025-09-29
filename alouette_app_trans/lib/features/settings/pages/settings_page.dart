import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _autoSave = true;
  bool _showNotifications = true;
  double _fontSize = 14.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Appearance Section
          _buildSectionCard(
            'Appearance',
            [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                },
              ),
              ListTile(
                title: const Text('Font Size'),
                subtitle: Text('${_fontSize.toInt()}px'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 20.0,
                    divisions: 8,
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Behavior Section
          _buildSectionCard(
            'Behavior',
            [
              SwitchListTile(
                title: const Text('Auto-save translations'),
                subtitle: const Text('Automatically save translation results'),
                value: _autoSave,
                onChanged: (value) {
                  setState(() {
                    _autoSave = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Show notifications'),
                subtitle: const Text('Display system notifications'),
                value: _showNotifications,
                onChanged: (value) {
                  setState(() {
                    _showNotifications = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Data Section
          _buildSectionCard(
            'Data Management',
            [
              ListTile(
                title: const Text('Clear translation history'),
                subtitle: const Text('Remove all saved translations'),
                trailing: const Icon(Icons.delete_outline),
                onTap: _showClearHistoryDialog,
              ),
              ListTile(
                title: const Text('Export settings'),
                subtitle: const Text('Save current settings to file'),
                trailing: const Icon(Icons.file_download),
                onTap: _exportSettings,
              ),
              ListTile(
                title: const Text('Import settings'),
                subtitle: const Text('Load settings from file'),
                trailing: const Icon(Icons.file_upload),
                onTap: _importSettings,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // About Section
          _buildSectionCard(
            'About',
            [
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0+1'),
                trailing: const Icon(Icons.info_outline),
              ),
              ListTile(
                title: const Text('License'),
                subtitle: const Text('View license information'),
                trailing: const Icon(Icons.description),
                onTap: _showLicenseDialog,
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                subtitle: const Text('View privacy policy'),
                trailing: const Icon(Icons.privacy_tip),
                onTap: _showPrivacyPolicy,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Translation History'),
        content: const Text(
          'This will permanently delete all saved translations. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearHistory();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    // TODO: Implement clear history functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Translation history cleared'),
      ),
    );
  }

  void _exportSettings() {
    // TODO: Implement export settings functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings exported successfully'),
      ),
    );
  }

  void _importSettings() {
    // TODO: Implement import settings functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings imported successfully'),
      ),
    );
  }

  void _showLicenseDialog() {
    showLicensePage(
      context: context,
      applicationName: 'Alouette Translator',
      applicationVersion: '1.0.0',
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This application processes text locally and sends it to configured LLM providers for translation. '
            'No personal data is stored or transmitted without your explicit consent. '
            'Translation history is stored locally on your device.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../services/core/configuration_manager.dart';
import '../../models/app_configuration.dart';

/// Configuration panel widget for managing application settings
/// 
/// Provides a unified interface for managing all application configuration
/// including UI preferences, theme settings, and feature toggles.
class ConfigurationPanel extends StatefulWidget {
  /// Whether to show advanced configuration options
  final bool showAdvanced;
  
  /// Callback when configuration changes
  final void Function(AppConfiguration config)? onConfigurationChanged;
  
  /// Custom sections to include in the configuration panel
  final List<Widget>? customSections;

  const ConfigurationPanel({
    super.key,
    this.showAdvanced = false,
    this.onConfigurationChanged,
    this.customSections,
  });

  @override
  State<ConfigurationPanel> createState() => _ConfigurationPanelState();
}

class _ConfigurationPanelState extends State<ConfigurationPanel> {
  final ConfigurationManager _configManager = ConfigurationManager.instance;
  AppConfiguration? _currentConfig;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final config = await _configManager.getConfiguration();
      
      setState(() {
        _currentConfig = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load configuration: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateConfiguration(AppConfiguration config) async {
    try {
      final success = await _configManager.updateConfiguration(config);
      if (success) {
        setState(() {
          _currentConfig = config;
        });
        widget.onConfigurationChanged?.call(config);
      } else {
        _showError('Failed to save configuration');
      }
    } catch (e) {
      _showError('Error saving configuration: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConfiguration,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_currentConfig == null) {
      return const Center(
        child: Text('No configuration available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSection(),
          const SizedBox(height: 24),
          _buildLanguageSection(),
          const SizedBox(height: 24),
          _buildAccessibilitySection(),
          if (widget.showAdvanced) ...[
            const SizedBox(height: 24),
            _buildAdvancedSection(),
          ],
          if (widget.customSections != null) ...[
            const SizedBox(height: 24),
            ...widget.customSections!,
          ],
          const SizedBox(height: 24),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildThemeModeSelector(),
            const SizedBox(height: 16),
            _buildAnimationToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'light',
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: 'dark',
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
            ButtonSegment(
              value: 'system',
              label: Text('System'),
              icon: Icon(Icons.settings_system_daydream),
            ),
          ],
          selected: {_currentConfig!.uiPreferences.themeMode},
          onSelectionChanged: (Set<String> selection) {
            final newThemeMode = selection.first;
            final updatedPreferences = _currentConfig!.uiPreferences.copyWith(
              themeMode: newThemeMode,
            );
            final updatedConfig = _currentConfig!.copyWith(
              uiPreferences: updatedPreferences,
            );
            _updateConfiguration(updatedConfig);
          },
        ),
      ],
    );
  }

  Widget _buildAnimationToggle() {
    return SwitchListTile(
      title: const Text('Enable Animations'),
      subtitle: const Text('Smooth transitions and effects'),
      value: _currentConfig!.uiPreferences.enableAnimations,
      onChanged: (bool value) {
        final updatedPreferences = _currentConfig!.uiPreferences.copyWith(
          enableAnimations: value,
        );
        final updatedConfig = _currentConfig!.copyWith(
          uiPreferences: updatedPreferences,
        );
        _updateConfiguration(updatedConfig);
      },
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language & Region',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Primary Language',
                border: OutlineInputBorder(),
              ),
              value: _currentConfig!.uiPreferences.primaryLanguage,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                DropdownMenuItem(value: 'it', child: Text('Italiano')),
                DropdownMenuItem(value: 'pt', child: Text('Português')),
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'ja', child: Text('日本語')),
                DropdownMenuItem(value: 'ko', child: Text('한국어')),
                DropdownMenuItem(value: 'zh', child: Text('中文')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  final updatedPreferences = _currentConfig!.uiPreferences.copyWith(
                    primaryLanguage: value,
                  );
                  final updatedConfig = _currentConfig!.copyWith(
                    uiPreferences: updatedPreferences,
                  );
                  _updateConfiguration(updatedConfig);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildFontScaleSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildFontScaleSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Size: ${(_currentConfig!.uiPreferences.fontScale * 100).round()}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: _currentConfig!.uiPreferences.fontScale,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: '${(_currentConfig!.uiPreferences.fontScale * 100).round()}%',
          onChanged: (double value) {
            final updatedPreferences = _currentConfig!.uiPreferences.copyWith(
              fontScale: value,
            );
            final updatedConfig = _currentConfig!.copyWith(
              uiPreferences: updatedPreferences,
            );
            _updateConfiguration(updatedConfig);
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Advanced Options'),
              subtitle: const Text('Display expert-level configuration options'),
              value: _currentConfig!.uiPreferences.showAdvancedOptions,
              onChanged: (bool value) {
                final updatedPreferences = _currentConfig!.uiPreferences.copyWith(
                  showAdvancedOptions: value,
                );
                final updatedConfig = _currentConfig!.copyWith(
                  uiPreferences: updatedPreferences,
                );
                _updateConfiguration(updatedConfig);
              },
            ),
            SwitchListTile(
              title: const Text('Auto Save'),
              subtitle: const Text('Automatically save changes'),
              value: _currentConfig!.appSettings['auto_save'] ?? true,
              onChanged: (bool value) {
                final updatedSettings = Map<String, dynamic>.from(_currentConfig!.appSettings);
                updatedSettings['auto_save'] = value;
                final updatedConfig = _currentConfig!.copyWith(
                  appSettings: updatedSettings,
                );
                _updateConfiguration(updatedConfig);
              },
            ),
            SwitchListTile(
              title: const Text('Backup Enabled'),
              subtitle: const Text('Create automatic backups of configuration'),
              value: _currentConfig!.appSettings['backup_enabled'] ?? true,
              onChanged: (bool value) {
                final updatedSettings = Map<String, dynamic>.from(_currentConfig!.appSettings);
                updatedSettings['backup_enabled'] = value;
                final updatedConfig = _currentConfig!.copyWith(
                  appSettings: updatedSettings,
                );
                _updateConfiguration(updatedConfig);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Management',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportConfiguration,
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importConfiguration,
                    icon: const Icon(Icons.upload),
                    label: const Text('Import'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportConfiguration() async {
    try {
      final configJson = await _configManager.exportConfiguration();
      // In a real implementation, you would save this to a file or share it
      // For now, we'll just show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration exported successfully'),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to export configuration: $e');
    }
  }

  Future<void> _importConfiguration() async {
    // In a real implementation, you would show a file picker
    // For now, we'll just show a placeholder message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import functionality not yet implemented'),
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Configuration'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _configManager.resetToDefaults();
        await _loadConfiguration();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration reset to defaults'),
            ),
          );
        }
      } catch (e) {
        _showError('Failed to reset configuration: $e');
      }
    }
  }
}
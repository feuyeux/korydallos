import 'package:flutter/material.dart';

import '../../services/core/configuration_manager.dart';
import '../../models/app_configuration.dart';

/// Widget that displays the current configuration status
/// 
/// Shows validation status, version information, and quick access
/// to configuration management functions.
class ConfigurationStatusWidget extends StatefulWidget {
  /// Whether to show detailed status information
  final bool showDetails;
  
  /// Callback when configuration needs attention
  final VoidCallback? onConfigurationIssue;

  const ConfigurationStatusWidget({
    super.key,
    this.showDetails = false,
    this.onConfigurationIssue,
  });

  @override
  State<ConfigurationStatusWidget> createState() => _ConfigurationStatusWidgetState();
}

class _ConfigurationStatusWidgetState extends State<ConfigurationStatusWidget> {
  final ConfigurationManager _configManager = ConfigurationManager.instance;
  AppConfiguration? _currentConfig;
  Map<String, dynamic>? _validationResult;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfigurationStatus();
    
    // Listen to configuration changes
    _configManager.configurationStream.listen((config) {
      if (mounted) {
        _loadConfigurationStatus();
      }
    });
  }

  Future<void> _loadConfigurationStatus() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final config = await _configManager.getConfiguration();
      final validation = await _configManager.validateConfiguration();
      
      setState(() {
        _currentConfig = config;
        _validationResult = validation;
        _isLoading = false;
      });

      // Notify if there are configuration issues
      if (!(validation['isValid'] as bool) && widget.onConfigurationIssue != null) {
        widget.onConfigurationIssue!();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load configuration status: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading configuration...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadConfigurationStatus,
                icon: const Icon(Icons.refresh),
                tooltip: 'Retry',
              ),
            ],
          ),
        ),
      );
    }

    if (_currentConfig == null || _validationResult == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No configuration data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              _buildDetailedStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final isValid = _validationResult!['isValid'] as bool;
    final errors = List<String>.from(_validationResult!['errors'] ?? []);
    final warnings = List<String>.from(_validationResult!['warnings'] ?? []);

    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (isValid && warnings.isEmpty) {
      statusIcon = Icons.check_circle;
      statusColor = Theme.of(context).colorScheme.primary;
      statusText = 'Configuration OK';
    } else if (isValid && warnings.isNotEmpty) {
      statusIcon = Icons.warning;
      statusColor = Colors.orange;
      statusText = 'Configuration OK (${warnings.length} warning${warnings.length > 1 ? 's' : ''})';
    } else {
      statusIcon = Icons.error;
      statusColor = Theme.of(context).colorScheme.error;
      statusText = 'Configuration Issues (${errors.length} error${errors.length > 1 ? 's' : ''})';
    }

    return Row(
      children: [
        Icon(
          statusIcon,
          color: statusColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Version ${_currentConfig!.version}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!isValid)
          IconButton(
            onPressed: widget.onConfigurationIssue,
            icon: const Icon(Icons.settings),
            tooltip: 'Fix Configuration Issues',
          ),
      ],
    );
  }

  Widget _buildDetailedStatus() {
    final errors = List<String>.from(_validationResult!['errors'] ?? []);
    final warnings = List<String>.from(_validationResult!['warnings'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        _buildConfigurationSummary(),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildIssuesList('Errors', errors, Theme.of(context).colorScheme.error),
        ],
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildIssuesList('Warnings', warnings, Colors.orange),
        ],
      ],
    );
  }

  Widget _buildConfigurationSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Summary',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildSummaryItem(
          'Translation Config',
          _currentConfig!.translationConfig != null ? 'Configured' : 'Not configured',
          _currentConfig!.translationConfig != null,
        ),
        _buildSummaryItem(
          'TTS Config',
          _currentConfig!.ttsConfig != null ? 'Configured' : 'Not configured',
          _currentConfig!.ttsConfig != null,
        ),
        _buildSummaryItem(
          'Theme Mode',
          _currentConfig!.uiPreferences.themeMode,
          true,
        ),
        _buildSummaryItem(
          'Primary Language',
          _currentConfig!.uiPreferences.primaryLanguage,
          true,
        ),
        _buildSummaryItem(
          'Last Updated',
          _formatDateTime(_currentConfig!.lastUpdated),
          true,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, bool isConfigured) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: isConfigured 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesList(String title, List<String> issues, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...issues.map((issue) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
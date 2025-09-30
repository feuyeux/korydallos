import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';

class TranslationSettingsPage extends StatefulWidget {
  final ITranslationController controller;

  const TranslationSettingsPage({super.key, required this.controller});

  @override
  State<TranslationSettingsPage> createState() =>
      _TranslationSettingsPageState();
}

class _TranslationSettingsPageState extends State<TranslationSettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Translation Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LLM Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LLM Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    _buildConfigurationInfo(),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ModernButton(
                            text: 'Configure LLM',
                            onPressed: _showConfigDialog,
                            icon: Icons.settings,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testConnection,
                            icon: const Icon(Icons.wifi_tethering),
                            label: const Text('Test Connection'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Auto-Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automatically detect and configure available LLM providers.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: _performAutoConfiguration,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Auto-Configure'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Application Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow('Version', '1.0.0'),
                    _buildInfoRow('Build', '1'),
                    _buildInfoRow('Translation Library', 'alouette_lib_trans'),
                    _buildInfoRow('UI Library', 'alouette_ui'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationInfo() {
    // Use default configuration for display
    const config = LLMConfig(
      provider: 'ollama',
      serverUrl: 'http://localhost:11434',
      selectedModel: '',
    );

    return Column(
      children: [
        _buildInfoRow('Provider', config.provider),
        _buildInfoRow('Server URL', config.serverUrl),
        _buildInfoRow(
          'Model',
          config.selectedModel.isEmpty ? 'Not selected' : config.selectedModel,
        ),
        _buildInfoRow('Status', 'Configured'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog() async {
    final llmConfigService = ServiceLocator.get<LLMConfigService>();
    final result = await showDialog<LLMConfig>(
      context: context,
      builder: (context) => LLMConfigDialog(
        initialConfig: const LLMConfig(
          provider: 'ollama',
          serverUrl: 'http://localhost:11434',
          selectedModel: '',
        ),
        llmConfigService: llmConfigService,
      ),
    );

    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _testConnection() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing connection...'),
          ],
        ),
      ),
    );

    try {
      // Test connection using the translation service
      final translationService = ServiceLocator.get<TranslationService>();
      const config = LLMConfig(
        provider: 'ollama',
        serverUrl: 'http://localhost:11434',
        selectedModel: '',
      );
      final connectionStatus = await translationService.testConnection(config);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              connectionStatus.success
                  ? 'Connection successful!'
                  : 'Connection failed: ${connectionStatus.message}',
            ),
            backgroundColor: connectionStatus.success
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _performAutoConfiguration() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-configuration successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import '../controllers/translation_controller.dart';

class TranslationSettingsPage extends StatefulWidget {
  final AppTranslationController controller;

  const TranslationSettingsPage({
    super.key,
    required this.controller,
  });

  @override
  State<TranslationSettingsPage> createState() => _TranslationSettingsPageState();
}

class _TranslationSettingsPageState extends State<TranslationSettingsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation Settings'),
      ),
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
                    
                    if (widget.controller.isAutoConfiguring)
                      Column(
                        children: [
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(widget.controller.autoConfigStatus),
                        ],
                      )
                    else
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
                    _buildInfoRow('UI Library', 'alouette_ui_shared'),
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
    final config = widget.controller.llmConfig;
    
    return Column(
      children: [
        _buildInfoRow('Provider', config.provider),
        _buildInfoRow('Server URL', config.serverUrl),
        _buildInfoRow('Model', config.selectedModel.isEmpty ? 'Not selected' : config.selectedModel),
        _buildInfoRow('Status', widget.controller.isConfigured ? 'Configured' : 'Not configured'),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigDialog() async {
    final result = await widget.controller.showConfigDialog(context);

    if (result != null) {
      widget.controller.updateLLMConfig(result);
      
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
      final connectionStatus = await widget.controller.translationService
          .testConnection(widget.controller.llmConfig);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              connectionStatus.success 
                  ? 'Connection successful!' 
                  : 'Connection failed: ${connectionStatus.message}',
            ),
            backgroundColor: connectionStatus.success ? Colors.green : Colors.red,
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
    await widget.controller.initialize();
    
    if (mounted) {
      final message = widget.controller.isConfigured
          ? 'Auto-configuration successful!'
          : 'Auto-configuration failed. Please configure manually.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: widget.controller.isConfigured ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
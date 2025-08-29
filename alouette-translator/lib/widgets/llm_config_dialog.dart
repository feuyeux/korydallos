import 'package:flutter/material.dart';
import '../models/translation_models.dart';
import '../services/llm_config_service.dart';
import '../constants/app_constants.dart';

class LLMConfigDialog extends StatefulWidget {
  final LLMConfig initialConfig;
  final LLMConfigService llmConfigService;

  const LLMConfigDialog({
    super.key,
    required this.initialConfig,
    required this.llmConfigService,
  });

  @override
  State<LLMConfigDialog> createState() => _LLMConfigDialogState();
}

class _LLMConfigDialogState extends State<LLMConfigDialog> {
  late TextEditingController _serverUrlController;
  late TextEditingController _apiKeyController;
  String _selectedProvider = 'ollama';
  String _selectedModel = '';
  bool _isTestingConnection = false;
  String? _connectionMessage;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.initialConfig.provider;
    _serverUrlController = TextEditingController(
      text: widget.initialConfig.serverUrl,
    );
    _apiKeyController = TextEditingController(
      text: widget.initialConfig.apiKey ?? '',
    );
    _selectedModel = widget.initialConfig.selectedModel;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LLM Configuration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Provider Selection
            Text('Provider', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              items: llmProviders.map((provider) {
                return DropdownMenuItem(
                  value: provider['value'],
                  child: Text(provider['name']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                    _connectionMessage = null;
                    _selectedModel = '';
                    _updateServerUrlForProvider(value);
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select LLM provider',
              ),
            ),

            const SizedBox(height: 16),

            // Server URL
            Text('Server URL', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'http://localhost:11434',
              ),
              onChanged: (_) {
                setState(() {
                  _connectionMessage = null;
                  _selectedModel = '';
                });
              },
            ),

            const SizedBox(height: 16),

            // API Key (for LM Studio)
            if (_selectedProvider == 'lmstudio') ...[
              Text(
                'API Key (Optional)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter API key if required',
                ),
                obscureText: true,
                onChanged: (_) {
                  setState(() {
                    _connectionMessage = null;
                    _selectedModel = '';
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Test Connection Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTestingConnection ? null : _testConnection,
                child: _isTestingConnection
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Testing Connection...'),
                        ],
                      )
                    : const Text('Test Connection'),
              ),
            ),

            const SizedBox(height: 16),

            // Connection Status
            if (_connectionMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _connectionSuccess
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _connectionSuccess
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _connectionSuccess ? Icons.check_circle : Icons.error,
                      color: _connectionSuccess
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connectionMessage!,
                        style: TextStyle(
                          color: _connectionSuccess
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Model Selection
            if (_connectionSuccess &&
                widget.llmConfigService.availableModels.isNotEmpty) ...[
              Text('Model', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedModel.isEmpty ? null : _selectedModel,
                items: widget.llmConfigService.availableModels.map((model) {
                  return DropdownMenuItem(value: model, child: Text(model));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedModel = value ?? '';
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a model',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canSave() ? _saveConfig : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateServerUrlForProvider(String provider) {
    final port = defaultPorts[provider] ?? 11434;
    _serverUrlController.text = 'http://localhost:$port';
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionMessage = null;
    });

    try {
      final config = LLMConfig(
        provider: _selectedProvider,
        serverUrl: _serverUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim().isEmpty
            ? null
            : _apiKeyController.text.trim(),
        selectedModel: '',
      );

      final result = await widget.llmConfigService.testConnection(config);

      setState(() {
        _connectionSuccess = result['success'] as bool;
        _connectionMessage = result['message'] as String;
        if (_connectionSuccess) {
          // Reset model selection when connection succeeds
          _selectedModel = '';
        }
      });
    } catch (error) {
      setState(() {
        _connectionSuccess = false;
        _connectionMessage = 'Connection test failed: $error';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  bool _canSave() {
    return _serverUrlController.text.trim().isNotEmpty &&
        _connectionSuccess &&
        _selectedModel.isNotEmpty;
  }

  void _saveConfig() {
    final config = LLMConfig(
      provider: _selectedProvider,
      serverUrl: _serverUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isEmpty
          ? null
          : _apiKeyController.text.trim(),
      selectedModel: _selectedModel,
    );

    Navigator.of(context).pop(config);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}

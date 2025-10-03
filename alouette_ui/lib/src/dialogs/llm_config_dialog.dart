import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import '../constants/ui_constants.dart';
import '../tokens/dimension_tokens.dart';
import '../widgets/custom_button.dart';

class LLMConfigDialog extends StatefulWidget {
  final LLMConfig initialConfig;
  final TranslationService translationService;
  final bool useDialog;

  const LLMConfigDialog({
    super.key,
    required this.initialConfig,
    required this.translationService,
    this.useDialog = true,
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
  List<String> _availableModels = [];

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

    // Try to load available models if already configured
    _loadAvailableModels();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Load available models for the current configuration
  Future<void> _loadAvailableModels() async {
    try {
      final config = LLMConfig(
        provider: widget.initialConfig.provider,
        serverUrl: widget.initialConfig.serverUrl,
        apiKey: widget.initialConfig.apiKey,
        selectedModel: '',
      );

      final models = await widget.translationService.getAvailableModels(config);
      if (mounted && models.isNotEmpty) {
        setState(() {
          // Remove duplicates from the models list
          _availableModels = models.toSet().toList();
          _connectionSuccess = true;
          _connectionMessage =
              'Connected. ${_availableModels.length} models available.';
          // Ensure selected model is valid
          if (!_availableModels.contains(_selectedModel)) {
            _selectedModel = _availableModels.first;
          }
        });
      }
    } catch (e) {
      // Silently fail - user can test connection manually
    }
  }

  /// Test connection
  Future<void> _testConnection() async {
    if (_isTestingConnection) return;

    setState(() {
      _isTestingConnection = true;
      _connectionMessage = null;
      _connectionSuccess = false;
    });

    final config = LLMConfig(
      provider: _selectedProvider,
      serverUrl: _serverUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim().isEmpty
          ? null
          : _apiKeyController.text.trim(),
      selectedModel: '',
    );

    try {
      final result = await widget.translationService.testConnection(config);

      setState(() {
        _connectionSuccess = result.success;
        _connectionMessage = result.message;
        if (_connectionSuccess &&
            result.details != null &&
            result.details!['models'] != null) {
          // Remove duplicates from the models list
          _availableModels = List<String>.from(
            result.details!['models'],
          ).toSet().toList();
          if (_availableModels.isNotEmpty) {
            // Auto-select first available model if current selection is not available
            if (!_availableModels.contains(_selectedModel)) {
              _selectedModel = _availableModels.first;
            }
          }
        }
      });
    } catch (error) {
      setState(() {
        _connectionSuccess = false;
        _connectionMessage = 'Connection failed: $error';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  /// Save configuration
  void _saveConfig() {
    if (!_connectionSuccess || _selectedModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please test connection and select a model first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

  bool _canSave() {
    return _serverUrlController.text.trim().isNotEmpty &&
        _connectionSuccess &&
        _selectedModel.isNotEmpty;
  }

  void _updateServerUrlForProvider(String provider) {
    _serverUrlController.text =
        LLMProviders.defaultUrls[provider] ?? 'http://localhost:11434';
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    if (widget.useDialog) {
      return AlertDialog(
        title: const Text('LLM Configuration'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: content),
        ),
        actions: _buildActions(),
      );
    } else {
      return Dialog(
        child: Container(
          width: 500.0, // Standard dialog width
          padding: const EdgeInsets.all(SpacingTokens.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LLM Configuration',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: SpacingTokens.xxl),
              Flexible(child: SingleChildScrollView(child: content)),
              const SizedBox(height: SpacingTokens.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActions(),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider Selection
        Text('Provider', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedProvider,
          items: LLMProviders.providers.map((provider) {
            return DropdownMenuItem(
              value: provider['value'],
              child: Text(provider['name']!),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedProvider = value;
                _updateServerUrlForProvider(value);
                _connectionSuccess = false;
                _connectionMessage = null;
                _selectedModel = '';
              });
            }
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),

        const SizedBox(height: SpacingTokens.l),

        // Server URL
        Text('Server URL', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _serverUrlController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: 'http://localhost:11434',
          ),
          onChanged: (_) {
            setState(() {
              _connectionSuccess = false;
              _connectionMessage = null;
            });
          },
        ),

        const SizedBox(height: SpacingTokens.l),

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
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Leave empty if not required',
            ),
            obscureText: true,
            onChanged: (_) {
              setState(() {
                _connectionSuccess = false;
                _connectionMessage = null;
              });
            },
          ),
          const SizedBox(height: SpacingTokens.l),
        ],

        // Test Connection Button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            onPressed: _isTestingConnection ? null : _testConnection,
            text: _isTestingConnection ? 'Testing...' : 'Test Connection',
            icon: _isTestingConnection ? null : Icons.wifi,
            type: CustomButtonType.outline,
            size: CustomButtonSize.medium,
          ),
        ),

        const SizedBox(height: SpacingTokens.l),

        // Connection Status - maintain layout space
        Visibility(
          visible: _connectionMessage != null,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _connectionSuccess
                      ? Colors.green.shade50
                      : Colors.red.shade50,
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
                        _connectionMessage ?? '',
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
              const SizedBox(height: SpacingTokens.l),
            ],
          ),
        ),

        // Model Selection - maintain layout space
        Visibility(
          visible: _connectionSuccess && _availableModels.isNotEmpty,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Model', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _availableModels.contains(_selectedModel)
                    ? _selectedModel
                    : null,
                items: _availableModels.toSet().map((model) {
                  return DropdownMenuItem(
                    value: model,
                    child: Text(model, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedModel = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                hint: const Text('Select a model'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      CustomButton(
        onPressed: () => Navigator.of(context).pop(),
        text: 'Cancel',
        type: CustomButtonType.text,
        size: CustomButtonSize.medium,
      ),
      if (widget.useDialog) const SizedBox(width: 8),
      CustomButton(
        onPressed: _canSave() ? _saveConfig : null,
        text: 'Save',
        type: CustomButtonType.primary,
        size: CustomButtonSize.medium,
      ),
    ];
  }
}

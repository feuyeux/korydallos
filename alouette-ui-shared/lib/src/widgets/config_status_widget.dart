import 'package:flutter/material.dart';
import 'package:alouette_lib_trans/alouette_lib_trans.dart';
import 'modern_button.dart';

/// Shared configuration status indicator widget
/// Shows the current LLM connection status across translation apps
class ConfigStatusWidget extends StatelessWidget {
  final bool isAutoConfiguring;
  final bool isConfigured;
  final String autoConfigStatus;
  final LLMConfig llmConfig;
  final VoidCallback onConfigurePressed;

  const ConfigStatusWidget({
    super.key,
    required this.isAutoConfiguring,
    required this.isConfigured,
    required this.autoConfigStatus,
    required this.llmConfig,
    required this.onConfigurePressed,
  });

  @override
  Widget build(BuildContext context) {
    // If auto-configuring, show progress status
    if (isAutoConfiguring) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  autoConfigStatus.isEmpty
                      ? 'Auto-configuring LLM connection...'
                      : autoConfigStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If configured successfully, show success status
    if (isConfigured) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Connected to ${llmConfig.provider}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                      ),
                    ),
                    if (llmConfig.selectedModel.isNotEmpty)
                      Text(
                        'Model: ${llmConfig.selectedModel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If configuration failed, show error status
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Auto-configuration failed. Click the settings button to configure manually.',
              ),
            ),
            ModernButton(
              text: 'Configure',
              onPressed: onConfigurePressed,
              type: ModernButtonType.text,
              size: ModernButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }
}

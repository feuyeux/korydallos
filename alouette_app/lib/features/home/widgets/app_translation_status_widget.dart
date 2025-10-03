import 'package:flutter/material.dart';
import 'package:alouette_app_trans/alouette_app_trans.dart';
import 'package:alouette_ui/alouette_ui.dart';

/// App-specific translation status widget that uses AppTranslationController
/// This ensures the status is always in sync with the controller's state
class AppTranslationStatusWidget extends StatelessWidget {
  final AppTranslationController controller;

  const AppTranslationStatusWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        // If auto-configuring, show progress status
        if (controller.isAutoConfiguring) {
          return Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.autoConfigStatus.isEmpty
                          ? 'Auto-configuring LLM connection...'
                          : controller.autoConfigStatus,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade800,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If configured successfully, show success status
        if (controller.isConfigured) {
          return Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.llmConfig.selectedModel.isNotEmpty
                          ? 'Connected to ${controller.llmConfig.provider} - Model: ${controller.llmConfig.selectedModel}'
                          : 'Connected to ${controller.llmConfig.provider}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                Icon(Icons.warning, color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Auto-configuration failed. Click settings to configure manually.',
                    style: TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CustomButton(
                  text: 'Configure',
                  onPressed: () => _showConfigDialog(context),
                  type: CustomButtonType.text,
                  size: CustomButtonSize.small,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfigDialog(BuildContext context) async {
    await controller.showConfigDialog(context);
  }
}

import 'package:flutter/material.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../controllers/tts_controller.dart' as local;
import '../widgets/tts_input_section.dart';
import '../widgets/tts_control_section.dart';
import '../widgets/tts_status_section.dart';
import '../../../config/tts_app_config.dart';

/// Home page for the TTS application
class TTSHomePage extends StatefulWidget {
  const TTSHomePage({super.key});

  @override
  State<TTSHomePage> createState() => _TTSHomePageState();
}

class _TTSHomePageState extends State<TTSHomePage> {
  late local.TTSController _ttsController;
  final TextEditingController _textController = TextEditingController(
    text: TTSAppConfig.defaultText,
  );

  @override
  void initState() {
    super.initState();
    _ttsController = local.TTSController();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await _ttsController.initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showTTSSettings() async {
    // Show TTS configuration dialog
    final platformInfo = await _ttsController.getPlatformInfo();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('TTS Settings'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Engine: ${_ttsController.currentEngine?.name ?? 'None'}'),
                const SizedBox(height: 8),
                Text('Platform: ${platformInfo['platform'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text('Backend: ${platformInfo['currentBackend'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text('Supported Engines: ${platformInfo['supportedEngines']?.join(', ') ?? 'None'}'),
                const SizedBox(height: 8),
                Text('Available Engines: ${platformInfo['availableEngines']?.join(', ') ?? 'None'}'),
                const SizedBox(height: 8),
                Text('Recommended Engine: ${platformInfo['recommendedEngine'] ?? 'None'}'),
                const SizedBox(height: 16),
                const Text('Voice Parameters:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rate: ${_ttsController.rate.toStringAsFixed(1)}x'),
                Text('Pitch: ${_ttsController.pitch.toStringAsFixed(1)}x'),
                Text('Volume: ${(_ttsController.volume * 100).toInt()}%'),
                const SizedBox(height: 16),
                const Text('Platform Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Desktop: ${platformInfo['isDesktop'] ?? false}'),
                Text('Mobile: ${platformInfo['isMobile'] ?? false}'),
                Text('Web: ${platformInfo['isWeb'] ?? false}'),
                Text('Process Execution: ${platformInfo['supportsProcessExecution'] ?? false}'),
                Text('File System: ${platformInfo['supportsFileSystem'] ?? false}'),
              ],
            ),
          ),
          actions: [
            ModernButton(
              onPressed: () => Navigator.of(context).pop(),
              text: 'Close',
              type: ModernButtonType.text,
              size: ModernButtonSize.medium,
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: TTSAppConfig.appTitle,
        actions: [
          ThemeSwitcher(
            onThemeChanged: () {
              // Theme change is handled automatically by the ThemeService
              // This callback can be used for additional actions if needed
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTTSSettings,
            tooltip: 'TTS Settings',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _ttsController,
        builder: (context, child) {
          // Show error if there's one
          if (_ttsController.lastError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showError(_ttsController.lastError!);
            });
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Status section
                TTSStatusSection(
                  controller: _ttsController,
                  onConfigurePressed: _showTTSSettings,
                ),
                const SizedBox(height: 8),

                // Text input and voice selection
                Expanded(
                  flex: 3,
                  child: TTSInputSection(
                    controller: _ttsController,
                    textController: _textController,
                  ),
                ),

                const SizedBox(height: 8),

                // TTS controls and parameters
                Expanded(
                  flex: 2,
                  child: TTSControlSection(
                    controller: _ttsController,
                    textController: _textController,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
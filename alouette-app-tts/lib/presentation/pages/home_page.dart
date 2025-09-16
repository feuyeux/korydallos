import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController(
    text: '你好，我可以为你朗读。Hello, I can read for you.',
  );

  bool _isPlaying = false;
  bool _isInitialized = false;
  String? _currentVoice;
  VoiceService? _voiceService;
  TTSEngineType? _currentEngine;

  // TTS parameters
  double _rate = 1.0;
  double _pitch = 1.0;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    try {
      await SharedTTSManager.getService();
      _voiceService = await SharedTTSManager.getVoiceService();
      _currentEngine = SharedTTSManager.currentEngine;

      // Load voices using VoiceService
      final voices = await _voiceService!.getAllVoices();

      if (mounted) {
        setState(() {
          if (voices.isNotEmpty) {
            _currentVoice = voices.first.name;
          }
          _isInitialized = true;
        });
      }
    } catch (e) {
      await _showDetailedError(e);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Show TTS configuration dialog
  Future<void> _showTTSConfig() async {
    final service = await SharedTTSManager.getService();
    await showDialog(
      context: context,
      builder: (context) => TTSConfigDialog(ttsService: service),
    );
  }

  /// Show detailed error information and diagnostic suggestions
  Future<void> _showDetailedError(dynamic error) async {
    final diagnostics = await TTSDiagnostics.runFullDiagnostics();
    final report = TTSDiagnostics.generateReadableReport(diagnostics);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('TTS Error'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: ${error.toString()}'),
                const SizedBox(height: 16),
                const Text(
                  'Diagnostic Information:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(report),
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
            ModernButton(
              onPressed: () => _showTTSConfig(),
              text: 'Configure TTS',
              type: ModernButtonType.primary,
              size: ModernButtonSize.medium,
            ),
          ],
        ),
      );
    }
  }

  Future<void> _speak() async {
    if (!_isInitialized || _currentVoice == null) return;

    try {
      // 设置语音和参数
      // 设置完成回调
      // Note: Callback will need to be handled differently with shared manager

      // 更新播放状态
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }

      // 播放文本
      await SharedTTSManager.speakText(
        _textController.text,
        voiceName: _currentVoice,
      );
    } catch (e) {
      _showError('Failed to speak: ${e.toString()}');
    }
  }

  Future<void> _stop() async {
    try {
      // Note: SharedTTSManager doesn't have a direct stop method
      // This will need to be implemented differently

      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      _showError('Failed to stop: ${e.toString()}');
    }
  }

  Future<void> _changeVoice(String voice) async {
    try {
      // 直接更新状态，因为TTSService没有setVoice方法
      if (mounted) {
        setState(() {
          _currentVoice = voice;
        });
      }
    } catch (e) {
      _showError('Failed to change voice: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Alouette TTS',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTTSConfig,
            tooltip: 'TTS Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Status indicator - 更紧凑
            TTSStatusCard(
              isInitialized: _isInitialized,
              isPlaying: _isPlaying,
              currentEngine: _currentEngine,
              onConfigurePressed: _showTTSConfig,
            ),
            const SizedBox(height: 6),

            // Text input and voice selection area
            Expanded(
              flex: 3,
              child: TTSInputWidget(
                textController: _textController,
                currentVoice: _currentVoice,
                voiceService: _voiceService,
                isInitialized: _isInitialized,
                onVoiceChanged: _changeVoice,
              ),
            ),

            const SizedBox(height: 6),

            // TTS parameters and controls area
            Expanded(
              flex: 2,
              child: TTSControlWidget(
                rate: _rate,
                pitch: _pitch,
                volume: _volume,
                isPlaying: _isPlaying,
                isInitialized: _isInitialized,
                onRateChanged: (value) => setState(() => _rate = value),
                onPitchChanged: (value) => setState(() => _pitch = value),
                onVolumeChanged: (value) => setState(() => _volume = value),
                onSpeak: _speak,
                onStop: _stop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

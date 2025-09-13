import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'tts_parameters_widget.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
      builder: (context) => TTSConfigDialog(
        ttsService: service,
      ),
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
                const Text('Diagnostic Information:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(report),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => _showTTSConfig(),
              child: const Text('Configure TTS'),
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
      await SharedTTSManager.speakText(_textController.text, voiceName: _currentVoice);
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
      body: Column(
        children: [
          // Status bar
          Container(
            color: AppTheme.primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Engine: ${_currentEngine?.name ?? 'Not initialized'}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_isInitialized)
                  TTSStatusIndicator(isPlaying: _isPlaying),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(UISizes.spacingL),
              children: [
                // Text Input
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.text_fields),
                          SizedBox(width: 8),
                          Text('Text Input', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 16),
                      ModernTextField(
                        controller: _textController,
                        maxLines: 5,
                        hintText: 'Enter text to speak...',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: UISizes.spacingL),
                
                // Voice Selection
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.record_voice_over),
                          SizedBox(width: 8),
                          Text('Voice Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (_isInitialized && _voiceService != null)
                        FutureBuilder<List<Voice>>(
                          future: _voiceService!.getAllVoices(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            
                            final voices = snapshot.data ?? [];
                            if (voices.isEmpty) {
                              return const Text('No voices available');
                            }
                            
                            return ModernDropdown<String>(
                              value: _currentVoice ?? voices.first.name,
                              items: voices.map((voice) => DropdownMenuItem<String>(
                                value: voice.name,
                                child: Text('${voice.name} (${voice.locale})'),
                              )).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _changeVoice(value);
                                }
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: UISizes.spacingL),
                
                // TTS Parameters
                TTSParametersWidget(
                  rate: _rate,
                  pitch: _pitch,
                  volume: _volume,
                  onRateChanged: (value) {
                    setState(() {
                      _rate = value;
                    });
                  },
                  onPitchChanged: (value) {
                    setState(() {
                      _pitch = value;
                    });
                  },
                  onVolumeChanged: (value) {
                    setState(() {
                      _volume = value;
                    });
                  },
                ),
                
                const SizedBox(height: UISizes.spacingL),
                
                // Playback Controls
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.play_circle_outline),
                          SizedBox(width: 8),
                          Text('Playback Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '播放控制',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: UISizes.spacingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ModernButton(
                            text: _isPlaying ? '暂停' : '播放',
                            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                            onPressed: _isInitialized ? (_isPlaying ? _stop : _speak) : null,
                            type: ModernButtonType.primary,
                            size: ModernButtonSize.large,
                          ),
                          const SizedBox(width: UISizes.spacingM),
                          ModernButton(
                            text: '停止',
                            icon: Icons.stop,
                            onPressed: _isInitialized && _isPlaying ? _stop : null,
                            type: ModernButtonType.outline,
                            size: ModernButtonSize.large,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TTSStatusIndicator extends StatelessWidget {
  final bool isPlaying;
  
  const TTSStatusIndicator({Key? key, required this.isPlaying}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isPlaying ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UISizes.borderRadiusM),
        border: Border.all(
          color: isPlaying ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlaying ? Icons.volume_up : Icons.volume_off,
            color: isPlaying ? Colors.green : Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isPlaying ? 'Currently Speaking...' : 'Ready to Speak',
            style: TextStyle(
              color: isPlaying ? Colors.green : Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
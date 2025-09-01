import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

/// TTS主页面
class TTSHomePage extends StatefulWidget {
  const TTSHomePage({super.key});

  @override
  State<TTSHomePage> createState() => _TTSHomePageState();
}

class _TTSHomePageState extends State<TTSHomePage>
    with TickerProviderStateMixin {
  late UnifiedTTSService _ttsService;
  AudioPlayer? _audioPlayer;
  final TextEditingController _textController = TextEditingController(
    text: '你好，我可以为你朗读。Hello, I can read for you.',
  );

  bool _isPlaying = false;
  bool _isInitialized = false;
  String? _currentVoice;
  List<Voice>? _voices;
  TTSEngineType? _currentEngine;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTTS();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    try {
      print('开始初始化 TTS 服务...');
      _ttsService = UnifiedTTSService();
      print('TTS 服务对象创建成功');
      
      await _ttsService.initialize();
      print('TTS 服务初始化成功');
      
      _audioPlayer = AudioPlayer();
      print('音频播放器创建成功');

      // 获取当前引擎类型
      _currentEngine = _ttsService.currentEngine;
      print('当前引擎: $_currentEngine');

      // 获取可用的语音列表
      final voices = await _ttsService.getVoices();
      print('获取到 ${voices.length} 个语音');
      
      if (mounted) {
        setState(() {
          _voices = voices;
          if (voices.isNotEmpty) {
            _currentVoice = voices.first.name;
            print('设置默认语音: $_currentVoice');
          } else {
            print('警告: 没有可用的语音');
          }
          _isInitialized = true;
        });
        print('TTS 初始化完成，状态更新成功');
      }
    } catch (e, stackTrace) {
      print('TTS 初始化失败: $e');
      print('堆栈跟踪: $stackTrace');
      if (mounted) {
        _showError('初始化TTS失败: $e');
        setState(() {
          _isInitialized = true; // 即使失败也标记为已初始化，避免无限加载
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
    _pulseController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_textController.text.isEmpty) {
      _showError('请输入要朗读的文本');
      return;
    }

    // 详细检查服务状态
    if (!_isInitialized) {
      _showError('TTS服务未初始化');
      return;
    }

    if (_currentVoice == null) {
      _showError('未选择语音，当前可用语音数量: ${_voices?.length ?? 0}');
      return;
    }

    if (_audioPlayer == null) {
      _showError('音频播放器未初始化');
      return;
    }

    if (_ttsService == null) {
      _showError('TTS服务对象为空');
      return;
    }

    try {
      setState(() => _isPlaying = true);
      _pulseController.repeat(reverse: true);
      
      final audioData = await _ttsService.synthesizeText(
        _textController.text,
        _currentVoice!,
      );
      await _audioPlayer!.playBytes(audioData);
      
      setState(() => _isPlaying = false);
      _pulseController.stop();
      _pulseController.reset();
    } on TTSError catch (e) {
      setState(() => _isPlaying = false);
      _pulseController.stop();
      _pulseController.reset();
      String errorMessage = '播放失败: ${e.message}';
      if (e.code != null) {
        errorMessage += ' (Code: ${e.code})';
      }
      _showError(errorMessage);
    } catch (e) {
      setState(() => _isPlaying = false);
      _pulseController.stop();
      _pulseController.reset();
      _showError('播放失败: $e');
    }
  }

  Future<void> _stop() async {
    if (!_isInitialized) return;

    try {
      // Note: The new unified API doesn't have a stop method at the service level
      // Audio playback is handled by the AudioPlayer
      setState(() => _isPlaying = false);
      _pulseController.stop();
      _pulseController.reset();
    } catch (e) {
      if (mounted) {
        _showError('停止失败: $e');
      }
    }
  }

  Future<void> _switchEngine(TTSEngineType engineType) async {
    if (!_isInitialized) return;

    try {
      await _ttsService.switchEngine(engineType);
      setState(() {
        _currentEngine = engineType;
        _voices = null;
        _currentVoice = null;
      });

      // Reload voices for the new engine
      final voices = await _ttsService.getVoices();
      setState(() {
        _voices = voices;
        if (voices.isNotEmpty) {
          _currentVoice = voices.first.name;
        }
      });
    } catch (e) {
      _showError('切换引擎失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6366F1), Color(0xFFF8F9FA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 简化标题
                _buildHeader(),
                const SizedBox(height: 8),

                // 主内容区域
                Expanded(
                  child: _isInitialized
                      ? _buildMainContent()
                      : _buildLoadingCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.record_voice_over,
            color: Color(0xFF6366F1),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Alouette TTS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          PopupMenuButton<TTSEngineType>(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentEngine?.name ?? 'TTS',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: TTSEngineType.edge,
                child: Row(
                  children: [
                    Icon(
                      _currentEngine == TTSEngineType.edge 
                          ? Icons.radio_button_checked 
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Edge TTS'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TTSEngineType.flutter,
                child: Row(
                  children: [
                    Icon(
                      _currentEngine == TTSEngineType.flutter 
                          ? Icons.radio_button_checked 
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text('Flutter TTS'),
                  ],
                ),
              ),
            ],
            onSelected: (engineType) {
              if (engineType != _currentEngine) {
                _switchEngine(engineType);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // 文本输入区域 - 紧凑版
        Expanded(flex: 2, child: _buildCompactTextInput()),
        const SizedBox(height: 8),

        // 控制区域 - 紧凑版
        _buildCompactControls(),
        const SizedBox(height: 8),

        // 播放按钮
        _buildControlButtons(),
      ],
    );
  }

  Widget _buildCompactTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF3B82F6),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '文本输入',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '请输入要朗读的文本...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(12),
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactControls() {
    if (_voices == null || _voices!.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over,
                color: Color(0xFF10B981),
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                '选择声音',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentVoice,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                items: _voices!.map((voice) {
                  return DropdownMenuItem<String>(
                    value: voice.name,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${voice.displayName} (${voice.locale})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _currentVoice = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? _pulseAnimation.value : 1.0,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _isPlaying
                        ? const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isPlaying
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF6366F1))
                                .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isPlaying ? _stop : _speak,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlaying ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlaying ? '停止' : '播放',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            '正在初始化TTS引擎...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请稍候片刻',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

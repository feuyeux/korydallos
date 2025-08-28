import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

/// 紧凑版TTS主页面 - 一屏显示所有内容
class TTSHomePage extends StatefulWidget {
  const TTSHomePage({super.key});

  @override
  State<TTSHomePage> createState() => _TTSHomePageState();
}

class _TTSHomePageState extends State<TTSHomePage> with TickerProviderStateMixin {
  late AlouetteTTSService _ttsService;
  final TextEditingController _textController = TextEditingController(
    text: '你好，我可以为你朗读。Hello, I can read for you.',
  );

  bool _isPlaying = false;
  bool _isInitialized = false;
  double _speechRate = 1.0;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _selectedLanguage = 'zh-CN';
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _languages = [
    {'code': 'zh-CN', 'name': '中文'},
    {'code': 'en-US', 'name': 'English'},
    {'code': 'ja-JP', 'name': '日本語'},
    {'code': 'ko-KR', 'name': '한국어'},
  ];

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
      // First register services in the service locator
      await ServiceLocator.registerServices();
      
      _ttsService = AlouetteTTSService();
      
      await _ttsService.initialize(
        onStart: () {
          if (mounted) {
            setState(() => _isPlaying = true);
            _pulseController.repeat(reverse: true);
          }
        },
        onComplete: () {
          if (mounted) {
            setState(() => _isPlaying = false);
            _pulseController.stop();
            _pulseController.reset();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isPlaying = false);
            _pulseController.stop();
            _pulseController.reset();
            _showError('TTS Error: $error');
          }
        },
        config: AlouetteTTSConfig(
          languageCode: _selectedLanguage,
          speechRate: _speechRate,
          volume: _volume,
          pitch: _pitch,
        ),
      );
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('初始化TTS失败: $e');
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
    _pulseController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_textController.text.isEmpty) {
      _showError('请输入要朗读的文本');
      return;
    }

    try {
      final config = AlouetteTTSConfig(
        languageCode: _selectedLanguage,
        speechRate: _speechRate,
        volume: _volume,
        pitch: _pitch,
      );
      await _ttsService.speak(_textController.text, config: config);
    } catch (e) {
      _showError('播放失败: $e');
    }
  }

  Future<void> _stop() async {
    if (!_isInitialized) return;
    
    try {
      await _ttsService.stop();
    } catch (e) {
      if (mounted) {
        _showError('停止失败: $e');
      }
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
            colors: [
              Color(0xFF6366F1),
              Color(0xFFF8F9FA),
            ],
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
                  child: _isInitialized ? _buildMainContent() : _buildLoadingCard(),
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
          const Icon(Icons.record_voice_over, color: Color(0xFF6366F1), size: 20),
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
          Text(
            'Edge TTS',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // 文本输入区域 - 紧凑版
        Expanded(
          flex: 2,
          child: _buildCompactTextInput(),
        ),
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
              child:TextField(
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
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactControls() {
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
        children: [
          // 语言选择
          Row(
            children: [
              const Icon(Icons.language, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              const Text('语言', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                      items: _languages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(lang['name']!),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() => _selectedLanguage = value);
                          if (_isInitialized) {
                            final config = AlouetteTTSConfig(
                              languageCode: value,
                              speechRate: _speechRate,
                              volume: _volume,
                              pitch: _pitch,
                            );
                            await _ttsService.updateConfig(config);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 语速控制
          _buildSliderRow('语速', _speechRate, 0.3, 2.0, Icons.speed, (value) async {
            setState(() => _speechRate = value);
            if (_isInitialized) {
              final config = AlouetteTTSConfig(
                languageCode: _selectedLanguage,
                speechRate: value,
                volume: _volume,
                pitch: _pitch,
              );
              await _ttsService.updateConfig(config);
            }
          }),
          
          // 音量控制
          _buildSliderRow('音量', _volume, 0.0, 1.0, Icons.volume_up, (value) async {
            setState(() => _volume = value);
            if (_isInitialized) {
              final config = AlouetteTTSConfig(
                languageCode: _selectedLanguage,
                speechRate: _speechRate,
                volume: value,
                pitch: _pitch,
              );
              await _ttsService.updateConfig(config);
            }
          }),
          
          // 音调控制
          _buildSliderRow('音调', _pitch, 0.5, 2.0, Icons.tune, (value) async {
            setState(() => _pitch = value);
            if (_isInitialized) {
              final config = AlouetteTTSConfig(
                languageCode: _selectedLanguage,
                speechRate: _speechRate,
                volume: _volume,
                pitch: value,
              );
              await _ttsService.updateConfig(config);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    String label,
    double value,
    double min,
    double max,
    IconData icon,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 14),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 20,
              activeColor: const Color(0xFF6366F1),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
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
                        color: (_isPlaying ? const Color(0xFFEF4444) : const Color(0xFF6366F1))
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
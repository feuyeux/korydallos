import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DebugApp());
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug TTS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DebugPage(),
    );
  }
}

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String _status = '未初始化';
  String _error = '';
  UnifiedTTSService? _ttsService;
  List<Voice>? _voices;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    setState(() {
      _status = '正在初始化...';
      _error = '';
    });

    try {
      _ttsService = UnifiedTTSService();
      await _ttsService!.initialize();
      
      setState(() {
        _status = '初始化成功';
      });

      // 获取语音列表
      final voices = await _ttsService!.getVoices();
      setState(() {
        _voices = voices;
        _status = '获取到 ${voices.length} 个语音';
      });
    } catch (e) {
      setState(() {
        _status = '初始化失败';
        _error = e.toString();
      });
    }
  }

  Future<void> _testSynthesize() async {
    if (_ttsService == null || _voices == null || _voices!.isEmpty) {
      setState(() {
        _error = 'TTS 服务未准备就绪';
      });
      return;
    }

    setState(() {
      _status = '正在合成语音...';
      _error = '';
    });

    try {
      final audioData = await _ttsService!.synthesizeText(
        'Hello, this is a test.',
        _voices!.first.name,
      );
      
      setState(() {
        _status = '合成成功，音频大小: ${audioData.length} 字节';
      });

      // 尝试播放
      final player = AudioPlayer();
      await player.playBytes(audioData);
      
      setState(() {
        _status = '播放完成';
      });
    } catch (e) {
      setState(() {
        _status = '测试失败';
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('状态: $_status'),
            const SizedBox(height: 16),
            if (_error.isNotEmpty) ...[
              const Text('错误:', style: TextStyle(color: Colors.red)),
              Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            if (_voices != null) ...[
              Text('可用语音 (${_voices!.length}):'),
              Expanded(
                child: ListView.builder(
                  itemCount: _voices!.length,
                  itemBuilder: (context, index) {
                    final voice = _voices![index];
                    return ListTile(
                      title: Text(voice.displayName),
                      subtitle: Text('${voice.locale} - ${voice.gender}'),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _initTTS,
                  child: const Text('重新初始化'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _testSynthesize,
                  child: const Text('测试合成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ttsService?.dispose();
    super.dispose();
  }
}
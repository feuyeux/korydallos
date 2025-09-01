import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalApp());
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Test',
      home: const MinimalPage(),
    );
  }
}

class MinimalPage extends StatefulWidget {
  const MinimalPage({super.key});

  @override
  State<MinimalPage> createState() => _MinimalPageState();
}

class _MinimalPageState extends State<MinimalPage> {
  String _status = '准备测试';

  Future<void> _testTTS() async {
    setState(() {
      _status = '开始测试...';
    });

    try {
      // 动态导入 TTS 库
      final module = await import('package:alouette_lib_tts/alouette_tts.dart');
      
      setState(() {
        _status = '库导入成功';
      });

      // 创建 TTS 服务
      final ttsService = module.UnifiedTTSService();
      
      setState(() {
        _status = '服务创建成功';
      });

      // 初始化
      await ttsService.initialize();
      
      setState(() {
        _status = '初始化成功';
      });

      ttsService.dispose();
      
      setState(() {
        _status = '测试完成';
      });
    } catch (e) {
      setState(() {
        _status = '错误: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimal TTS Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testTTS,
              child: const Text('测试 TTS'),
            ),
          ],
        ),
      ),
    );
  }
}

// 动态导入函数
Future<dynamic> import(String uri) async {
  // 这里应该使用 dart:mirrors 或其他方式动态导入
  // 但为了简化，我们直接抛出错误来测试
  throw UnsupportedError('Dynamic import not supported in this context');
}
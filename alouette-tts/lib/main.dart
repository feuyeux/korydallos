import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化服务定位器
  await ServiceLocator.registerServices();
  
  runApp(const AlouetteTTSApp());
}

/// Alouette TTS 应用程序
class AlouetteTTSApp extends StatelessWidget {
  const AlouetteTTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette TTS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TTSHomePage(),
    );
  }
}

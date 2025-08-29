import 'package:flutter/material.dart';
import 'package:alouette_lib_tts/alouette_tts.dart';
import 'pages/tts_test_page.dart';

void main() {
  runApp(const TTSTestApp());
}

class TTSTestApp extends StatelessWidget {
  const TTSTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTS Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TTSTestPage(),
    );
  }
}

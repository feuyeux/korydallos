import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlouetteTTSApp());
}

/// Alouette TTS 应用程序
class AlouetteTTSApp extends StatelessWidget {
  const AlouetteTTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette TTS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

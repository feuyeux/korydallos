import 'package:flutter/material.dart';
import 'translation_page.dart';
import 'tts_test_page.dart';
import '../widgets/alouette_app_bar.dart';

/// 应用主页面
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AlouetteAppBar(),
      body: const TranslationPage(),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
              child: Text(
                'Alouette App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Translation'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('TTS Test'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TTSTestPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

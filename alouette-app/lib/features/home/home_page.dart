import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'home_controller.dart';
import '../translation/translation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Alouette Translator',
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const TranslationPage(),
    );
  }

  void _showSettings() {
    // TODO: 实现设置页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings page coming soon'),
      ),
    );
  }
}
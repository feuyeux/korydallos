import 'package:flutter/material.dart';
import 'package:alouette_ui_shared/alouette_ui_shared.dart';
import 'home_controller.dart';
import '../translation/translation_page.dart';
import '../tts/tts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final HomeController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Alouette App',
        showLogo: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.translate),
              text: 'Translation',
            ),
            Tab(
              icon: Icon(Icons.record_voice_over),
              text: 'Text-to-Speech',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TranslationPage(),
          TTSPage(),
        ],
      ),
    );
  }
}
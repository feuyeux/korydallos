import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alouette_ui/alouette_ui.dart';
import '../features/home/pages/home_page.dart';
import 'alouette_app.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  static const platform = MethodChannel('com.example.alouette/menu');
  bool _isAboutPageOpen = false;

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'showAbout') {
        _showAboutPage();
      }
    });
  }

  void _showAboutPage() {
    final context = navigatorKey.currentContext;
    if (context != null && !_isAboutPageOpen) {
      _isAboutPageOpen = true;
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => const AboutPage(
                appName: 'alouette-app',
                copyright: 'Copyright © 2025 com.example. All rights reserved.',
              ),
            ),
          )
          .then((_) {
            _isAboutPageOpen = false;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pages/app_home_page.dart';

void main() {
  debugPrint('Starting app initialization...');

  // Print environment info for debugging (only on non-web platforms)
  if (!kIsWeb) {
    try {
      final home = Platform.environment['HOME'];
      final path = Platform.environment['PATH'];
      debugPrint('Environment variables:');
      debugPrint('HOME: $home');
      debugPrint('PATH: $path');
    } catch (e) {
      debugPrint('Cannot access environment variables: $e');
    }
  }

  runApp(const AlouetteApp());
}

class AlouetteApp extends StatelessWidget {
  const AlouetteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alouette App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AppHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

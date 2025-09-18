import 'package:flutter/foundation.dart';

class HomeController {
  HomeController() {
    _initialize();
  }

  void _initialize() {
    debugPrint('HomeController: Initialized');
  }

  void dispose() {
    debugPrint('HomeController: Disposed');
  }
}
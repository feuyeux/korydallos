import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper function to find any of the provided finders
/// Replaces the non-existent .or() method on Finder
Finder findAnyOf(List<Finder> finders) {
  for (final finder in finders) {
    if (finder.evaluate().isNotEmpty) {
      return finder;
    }
  }
  // Return the first finder as fallback (will fail if none found)
  return finders.first;
}

/// Helper function to check if any of the finders has widgets
bool hasAnyOf(List<Finder> finders) {
  return finders.any((finder) => finder.evaluate().isNotEmpty);
}

/// Helper function to tap any of the provided finders
Future<void> tapAnyOf(WidgetTester tester, List<Finder> finders) async {
  final finder = findAnyOf(finders);
  if (finder.evaluate().isNotEmpty) {
    await tester.tap(finder);
  }
}
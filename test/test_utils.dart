import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A simple, font-free box used across tests so golden comparisons stay
/// stable across platforms and don't depend on text rendering.
Widget box(Color color, {double width = 60, double height = 40, Key? key}) {
  return Container(key: key, width: width, height: height, color: color);
}

/// Wraps [child] in the minimal ancestry a widget test needs
/// (Directionality via [MaterialApp] + a [Scaffold] body), then pumps it.
Future<void> pumpApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

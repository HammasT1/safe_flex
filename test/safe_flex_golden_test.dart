import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_flex/safe_flex.dart';

/// A fixed, font-free set of children so golden images are stable across
/// platforms: five colored blocks that together are far wider/taller than
/// the box each test constrains them to.
List<Widget> _blocks({required Axis direction}) {
  final colors = [
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];
  return [
    for (final color in colors)
      Container(
        width: direction == Axis.horizontal ? 50 : 40,
        height: direction == Axis.horizontal ? 40 : 50,
        color: color,
      ),
  ];
}

Future<void> _pumpGolden(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: RepaintBoundary(child: child)),
      ),
    ),
  );
}

void main() {
  group('golden - scroll strategy', () {
    testWidgets('horizontal row overflow renders scrollable content', (
      tester,
    ) async {
      await _pumpGolden(
        tester,
        SizedBox(
          width: 160,
          height: 60,
          child: SafeRow(
            strategy: OverflowStrategy.scroll,
            children: _blocks(direction: Axis.horizontal),
          ),
        ),
      );
      // The fallback strategy widget mounts on the frame after overflow is
      // first detected; pump once more so the golden captures it.
      await tester.pump();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/scroll_strategy.png'),
      );
    });
  });

  group('golden - wrap strategy', () {
    testWidgets('horizontal row overflow reflows onto multiple lines', (
      tester,
    ) async {
      await _pumpGolden(
        tester,
        SizedBox(
          width: 160,
          height: 160,
          child: SafeRow(
            strategy: OverflowStrategy.wrap,
            children: _blocks(direction: Axis.horizontal),
          ),
        ),
      );
      // The fallback strategy widget mounts on the frame after overflow is
      // first detected; pump once more so the golden captures it.
      await tester.pump();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/wrap_strategy.png'),
      );
    });
  });

  group('golden - scale strategy', () {
    testWidgets('horizontal row overflow scales content down to fit', (
      tester,
    ) async {
      await _pumpGolden(
        tester,
        SizedBox(
          width: 160,
          height: 60,
          child: SafeRow(
            strategy: OverflowStrategy.scale,
            children: _blocks(direction: Axis.horizontal),
          ),
        ),
      );
      // The fallback strategy widget mounts on the frame after overflow is
      // first detected; pump once more so the golden captures it.
      await tester.pump();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/scale_strategy.png'),
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_flex/safe_flex.dart';
import 'package:safe_flex/src/safe_flex_render.dart';

import 'test_utils.dart';

void main() {
  group('SafeColumn', () {
    testWidgets('lays children out vertically like Column when they fit', (
      tester,
    ) async {
      const keyA = Key('a');
      const keyB = Key('b');
      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 300,
          child: SafeColumn(
            children: [
              box(Colors.red, height: 50, key: keyA),
              box(Colors.blue, height: 50, key: keyB),
            ],
          ),
        ),
      );

      final rectA = tester.getRect(find.byKey(keyA));
      final rectB = tester.getRect(find.byKey(keyB));
      expect(rectB.top, rectA.bottom);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'applies the configured strategy when it overflows vertically',
      (tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 100,
            height: 80,
            child: SafeColumn(
              strategy: OverflowStrategy.scroll,
              children: [box(Colors.red, height: 400)],
            ),
          ),
        );

        final reporter = tester.allRenderObjects
            .whereType<RenderOverflowReporter>()
            .toSet()
            .single;
        expect(reporter.isOverflowing, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('defaults to OverflowStrategy.scroll', (tester) async {
      const column = SafeColumn(children: []);
      expect(column.strategy, OverflowStrategy.scroll);
    });

    testWidgets('onOverflow reports the strategy that was applied', (
      tester,
    ) async {
      OverflowStrategy? reported;
      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 80,
          child: SafeColumn(
            strategy: OverflowStrategy.clip,
            onOverflow: (strategy) => reported = strategy,
            children: [box(Colors.red, height: 400)],
          ),
        ),
      );
      await tester.pump();

      expect(reported, OverflowStrategy.clip);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_flex/safe_flex.dart';
import 'package:safe_flex/src/safe_flex_render.dart';

import 'test_utils.dart';

void main() {
  group('SafeRow', () {
    testWidgets('lays children out horizontally like Row when they fit', (
      tester,
    ) async {
      const keyA = Key('a');
      const keyB = Key('b');
      await pumpApp(
        tester,
        SizedBox(
          width: 300,
          height: 100,
          child: SafeRow(
            children: [
              box(Colors.red, width: 50, key: keyA),
              box(Colors.blue, width: 50, key: keyB),
            ],
          ),
        ),
      );

      final rectA = tester.getRect(find.byKey(keyA));
      final rectB = tester.getRect(find.byKey(keyB));
      expect(rectB.left, rectA.right);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'applies the configured strategy when it overflows horizontally',
      (tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 100,
            height: 60,
            child: SafeRow(
              strategy: OverflowStrategy.scroll,
              children: [box(Colors.red, width: 400)],
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
      const row = SafeRow(children: []);
      expect(row.strategy, OverflowStrategy.scroll);
    });

    testWidgets('onOverflow reports the strategy that was applied', (
      tester,
    ) async {
      OverflowStrategy? reported;
      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 60,
          child: SafeRow(
            strategy: OverflowStrategy.wrap,
            onOverflow: (strategy) => reported = strategy,
            children: [box(Colors.red, width: 400)],
          ),
        ),
      );
      await tester.pump();

      expect(reported, OverflowStrategy.wrap);
    });
  });
}

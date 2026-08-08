import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_flex/safe_flex.dart';
// Internal import: the test suite is allowed to reach into the package's
// own implementation to assert on the overflow-reporting state directly,
// rather than relying on brittle widget-tree shape checks.
import 'package:safe_flex/src/safe_flex_render.dart';

import 'test_utils.dart';

/// Returns whether the (unique) [RenderOverflowReporter] currently mounted
/// is reporting overflow.
bool _isOverflowing(WidgetTester tester) {
  return tester.allRenderObjects
      .whereType<RenderOverflowReporter>()
      .toSet()
      .single
      .isOverflowing;
}

void main() {
  group('SafeFlex - no overflow', () {
    testWidgets('horizontal layout matches a plain Row pixel-for-pixel', (
      tester,
    ) async {
      const keyA = Key('a');
      const keyB = Key('b');

      await pumpApp(
        tester,
        SizedBox(
          width: 300,
          height: 100,
          child: Row(
            children: [
              box(Colors.red, key: keyA),
              box(Colors.blue, key: keyB),
            ],
          ),
        ),
      );
      final rowRectA = tester.getRect(find.byKey(keyA));
      final rowRectB = tester.getRect(find.byKey(keyB));

      await pumpApp(
        tester,
        SizedBox(
          width: 300,
          height: 100,
          child: SafeRow(
            children: [
              box(Colors.red, key: keyA),
              box(Colors.blue, key: keyB),
            ],
          ),
        ),
      );
      final safeRectA = tester.getRect(find.byKey(keyA));
      final safeRectB = tester.getRect(find.byKey(keyB));

      expect(safeRectA, rowRectA);
      expect(safeRectB, rowRectB);
      expect(_isOverflowing(tester), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vertical layout matches a plain Column pixel-for-pixel', (
      tester,
    ) async {
      const keyA = Key('a');
      const keyB = Key('b');

      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 300,
          child: Column(
            children: [
              box(Colors.red, key: keyA),
              box(Colors.blue, key: keyB),
            ],
          ),
        ),
      );
      final colRectA = tester.getRect(find.byKey(keyA));
      final colRectB = tester.getRect(find.byKey(keyB));

      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 300,
          child: SafeColumn(
            children: [
              box(Colors.red, key: keyA),
              box(Colors.blue, key: keyB),
            ],
          ),
        ),
      );
      final safeRectA = tester.getRect(find.byKey(keyA));
      final safeRectB = tester.getRect(find.byKey(keyB));

      expect(safeRectA, colRectA);
      expect(safeRectB, colRectB);
      expect(_isOverflowing(tester), isFalse);
    });

    testWidgets('honors mainAxisAlignment and crossAxisAlignment like Flex', (
      tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 300,
          height: 200,
          child: SafeRow(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              box(Colors.red, width: 20, height: 20),
              box(Colors.blue, width: 20, height: 40),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_isOverflowing(tester), isFalse);
    });

    testWidgets('spacing inserts a fixed gap between children', (tester) async {
      const keyA = Key('a');
      const keyB = Key('b');
      await pumpApp(
        tester,
        SizedBox(
          width: 300,
          height: 100,
          child: SafeRow(
            spacing: 16,
            children: [
              box(Colors.red, width: 50, key: keyA),
              box(Colors.blue, width: 50, key: keyB),
            ],
          ),
        ),
      );
      final left = tester.getTopRight(find.byKey(keyA)).dx;
      final right = tester.getTopLeft(find.byKey(keyB)).dx;
      expect(right - left, 16);
    });
  });

  group('SafeFlex - overflow strategies', () {
    for (final strategy in OverflowStrategy.values) {
      testWidgets(
        '${strategy.name} strategy engages and paints without an overflow error',
        (tester) async {
          await pumpApp(
            tester,
            SizedBox(
              width: 120,
              height: 80,
              child: SafeRow(
                strategy: strategy,
                children: List.generate(
                  5,
                  (i) => box(
                    Colors.primaries[i % Colors.primaries.length],
                    width: 60,
                  ),
                ),
              ),
            ),
          );
          // The overflow is detected (and painting of the stale, still-fitting
          // Flex suppressed) on this very first frame...
          expect(_isOverflowing(tester), isTrue);
          expect(tester.takeException(), isNull);

          // ...and the fallback strategy widget is mounted on the next frame.
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(_isOverflowing(tester), isTrue);
        },
      );
    }

    testWidgets(
      'scroll strategy allows dragging to reveal off-screen content',
      (tester) async {
        const lastKey = Key('last');
        await pumpApp(
          tester,
          SizedBox(
            width: 100,
            height: 60,
            child: SafeRow(
              strategy: OverflowStrategy.scroll,
              children: [
                box(Colors.red, width: 80),
                box(Colors.green, width: 80),
                box(Colors.blue, width: 80, key: lastKey),
              ],
            ),
          ),
        );
        await tester.pump();
        expect(_isOverflowing(tester), isTrue);
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        final before = tester.getTopLeft(find.byKey(lastKey)).dx;
        await tester.drag(find.byType(SafeRow), const Offset(-1000, 0));
        await tester.pump();
        final after = tester.getTopLeft(find.byKey(lastKey)).dx;

        expect(after, lessThan(before));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('wrap strategy places overflowing children on a new run', (
      tester,
    ) async {
      const keyA = Key('a');
      const keyB = Key('b');
      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 200,
          child: SafeRow(
            strategy: OverflowStrategy.wrap,
            children: [
              box(Colors.red, width: 80, height: 30, key: keyA),
              box(Colors.blue, width: 80, height: 30, key: keyB),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(_isOverflowing(tester), isTrue);
      expect(find.byType(Wrap), findsOneWidget);

      final topA = tester.getTopLeft(find.byKey(keyA)).dy;
      final topB = tester.getTopLeft(find.byKey(keyB)).dy;
      expect(topB, greaterThan(topA));
    });

    testWidgets('shrink and scale strategies both shrink content to fit', (
      tester,
    ) async {
      for (final strategy in [
        OverflowStrategy.shrink,
        OverflowStrategy.scale,
      ]) {
        const keyA = Key('a');
        await pumpApp(
          tester,
          SizedBox(
            width: 100,
            height: 60,
            child: SafeRow(
              strategy: strategy,
              children: [box(Colors.red, width: 300, height: 300, key: keyA)],
            ),
          ),
        );
        await tester.pump();
        expect(_isOverflowing(tester), isTrue);
        expect(find.byType(FittedBox), findsOneWidget);

        // getSize() reports the child's own (unscaled) layout size, since
        // FittedBox scales via a paint-time transform rather than
        // re-laying the child out smaller. getRect() applies the full
        // ancestor transform chain, revealing the actual on-screen size.
        final onScreenSize = tester.getRect(find.byKey(keyA)).size;
        expect(onScreenSize.width, lessThanOrEqualTo(100));
        expect(onScreenSize.height, lessThanOrEqualTo(60));
      }
    });

    testWidgets('clip strategy clips overflowing content at the boundary', (
      tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 60,
          child: SafeRow(
            strategy: OverflowStrategy.clip,
            children: [box(Colors.red, width: 400)],
          ),
        ),
      );
      await tester.pump();
      expect(_isOverflowing(tester), isTrue);
      expect(tester.takeException(), isNull);
      // The overall SafeRow footprint stays clamped to the available space.
      expect(tester.getSize(find.byType(SafeRow)).width, 100);
    });
  });

  group('SafeFlex - onOverflow callback', () {
    testWidgets(
      'fires exactly once while the overflow persists across rebuilds',
      (tester) async {
        var callCount = 0;
        await pumpApp(
          tester,
          SizedBox(
            width: 100,
            height: 60,
            child: SafeRow(
              strategy: OverflowStrategy.scroll,
              onOverflow: (_) => callCount++,
              children: [box(Colors.red, width: 300)],
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(callCount, 1);
      },
    );

    testWidgets('does not fire when content never overflows', (tester) async {
      var callCount = 0;
      await pumpApp(
        tester,
        SizedBox(
          width: 300,
          height: 100,
          child: SafeRow(
            onOverflow: (_) => callCount++,
            children: [box(Colors.red, width: 50)],
          ),
        ),
      );
      await tester.pump();

      expect(callCount, 0);
    });

    testWidgets('fires again for a new overflow event after recovering', (
      tester,
    ) async {
      var callCount = 0;
      final children = [box(Colors.red, width: 300)];

      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 60,
          child: SafeRow(onOverflow: (_) => callCount++, children: children),
        ),
      );
      expect(callCount, 1);

      // Widen past the overflow threshold: the reporter should recover.
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 60,
          child: SafeRow(onOverflow: (_) => callCount++, children: children),
        ),
      );
      expect(_isOverflowing(tester), isFalse);
      expect(callCount, 1);

      // Narrow again: a *new* overflow event should fire the callback again.
      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 60,
          child: SafeRow(onOverflow: (_) => callCount++, children: children),
        ),
      );
      expect(_isOverflowing(tester), isTrue);
      expect(callCount, 2);
    });

    testWidgets(
      'debugLabel does not affect layout and is purely informational',
      (tester) async {
        await pumpApp(
          tester,
          SizedBox(
            width: 100,
            height: 60,
            child: SafeRow(
              debugLabel: 'profile-header',
              children: [box(Colors.red, width: 300)],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(_isOverflowing(tester), isTrue);
      },
    );
  });

  group('SafeFlex - edge cases', () {
    testWidgets('renders with an empty children list', (tester) async {
      await pumpApp(
        tester,
        const SizedBox(width: 100, height: 60, child: SafeRow(children: [])),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with a single child', (tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 100,
          height: 60,
          child: SafeRow(children: [box(Colors.red, width: 40)]),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_isOverflowing(tester), isFalse);
    });

    testWidgets('supports nesting a SafeFlex inside another SafeFlex', (
      tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 120,
          height: 120,
          child: SafeRow(
            strategy: OverflowStrategy.scroll,
            children: [
              SafeColumn(
                strategy: OverflowStrategy.clip,
                children: List.generate(
                  6,
                  (i) => box(
                    Colors.primaries[i % Colors.primaries.length],
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              box(Colors.black, width: 200, height: 30),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles very long text without throwing', (tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 150,
          height: 60,
          child: SafeRow(
            strategy: OverflowStrategy.shrink,
            children: [
              Text(
                'This is a very long username that will not fit in the available space',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'clip strategy does not throw when the cross axis is unbounded',
      (tester) async {
        // Regression test: a horizontal SafeRow's cross axis (height) is
        // commonly unbounded in real layouts — e.g. inside a Column or a
        // ListView item, as opposed to every other test in this file which
        // wraps content in a SizedBox with both dimensions bounded.
        // OverflowBox's default fit sizes itself to "as large as the parent
        // allows," which previously threw an infinite-size layout error
        // whenever the incoming constraint had an unbounded dimension.
        await pumpApp(
          tester,
          SizedBox(
            width: 100,
            child: Column(
              children: [
                SafeRow(
                  strategy: OverflowStrategy.clip,
                  children: [box(Colors.red, width: 400)],
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        expect(_isOverflowing(tester), isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('handles near-zero width and height constraints', (
      tester,
    ) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 0.5,
          height: 0.5,
          child: SafeRow(children: [box(Colors.red, width: 40, height: 40)]),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles zero children with a non-zero spacing value', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 100,
          height: 60,
          child: SafeRow(spacing: 12, children: []),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'updates its axis in place when direction changes on an already-mounted SafeFlex',
      (tester) async {
        const key = Key('safe-flex');
        await pumpApp(
          tester,
          SizedBox(
            width: 300,
            height: 300,
            child: SafeFlex(
              key: key,
              children: [box(Colors.red, width: 40, height: 40)],
            ),
          ),
        );
        expect(tester.takeException(), isNull);

        await pumpApp(
          tester,
          SizedBox(
            width: 300,
            height: 300,
            child: SafeFlex(
              key: key,
              direction: Axis.vertical,
              children: [box(Colors.red, width: 40, height: 40)],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('SafeFlex - diagnostics', () {
    test(
      'debugFillProperties exposes the configured values for the widget inspector',
      () {
        const widget = SafeFlex(
          strategy: OverflowStrategy.wrap,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 8,
          debugLabel: 'toolbar',
          children: [],
        );

        final builder = DiagnosticPropertiesBuilder();
        widget.debugFillProperties(builder);
        final names = builder.properties.map((p) => p.name).toList();

        expect(
          names,
          containsAll([
            'direction',
            'strategy',
            'mainAxisAlignment',
            'mainAxisSize',
            'crossAxisAlignment',
            'spacing',
            'debugLabel',
          ]),
        );
        expect(
          builder.properties.firstWhere((p) => p.name == 'strategy').value,
          OverflowStrategy.wrap,
        );
        expect(
          builder.properties.firstWhere((p) => p.name == 'debugLabel').value,
          'toolbar',
        );
      },
    );
  });

  group('SafeFlex - alignment mapping across fallback strategies', () {
    const mainAxisAlignments = MainAxisAlignment.values;
    // CrossAxisAlignment.baseline requires a textBaseline to be configured
    // on the Flex itself (a Flex/Row/Column requirement, not specific to
    // SafeFlex), so it's exercised separately rather than in this loop.
    final crossAxisAlignments = CrossAxisAlignment.values.where(
      (v) => v != CrossAxisAlignment.baseline,
    );

    for (final mainAxisAlignment in mainAxisAlignments) {
      testWidgets(
        'wrap strategy supports mainAxisAlignment.${mainAxisAlignment.name}',
        (tester) async {
          await pumpApp(
            tester,
            SizedBox(
              width: 100,
              height: 200,
              child: SafeRow(
                strategy: OverflowStrategy.wrap,
                mainAxisAlignment: mainAxisAlignment,
                children: [
                  box(Colors.red, width: 80, height: 30),
                  box(Colors.blue, width: 80, height: 30),
                ],
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final crossAxisAlignment in crossAxisAlignments) {
      testWidgets(
        'wrap strategy supports crossAxisAlignment.${crossAxisAlignment.name}',
        (tester) async {
          await pumpApp(
            tester,
            SizedBox(
              width: 100,
              height: 200,
              child: SafeRow(
                strategy: OverflowStrategy.wrap,
                crossAxisAlignment: crossAxisAlignment,
                children: [
                  box(Colors.red, width: 80, height: 30),
                  box(Colors.blue, width: 80, height: 30),
                ],
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'wrap strategy supports crossAxisAlignment.baseline given a textBaseline',
      (tester) async {
        await pumpApp(
          tester,
          const SizedBox(
            width: 100,
            height: 200,
            child: SafeRow(
              strategy: OverflowStrategy.wrap,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [Text('first'), Text('second')],
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    for (final mainAxisAlignment in mainAxisAlignments) {
      testWidgets(
        'clip strategy supports mainAxisAlignment.${mainAxisAlignment.name}',
        (tester) async {
          await pumpApp(
            tester,
            SizedBox(
              width: 100,
              height: 60,
              child: SafeRow(
                strategy: OverflowStrategy.clip,
                mainAxisAlignment: mainAxisAlignment,
                children: [box(Colors.red, width: 300)],
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}

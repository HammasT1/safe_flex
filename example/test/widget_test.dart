import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_flex_example/main.dart';

void main() {
  testWidgets('demo app renders every OverflowStrategy card without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(const SafeFlexExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Before — plain Row'), findsOneWidget);
    expect(find.textContaining('OverflowStrategy.'), findsWidgets);
    // The "Before" card intentionally shows a real, unmodified Row that
    // overflows — that's the whole point of the comparison — so it's
    // expected (and consumed here) rather than treated as a test failure.
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('dragging the width slider updates the simulated width label', (
    tester,
  ) async {
    await tester.pumpWidget(const SafeFlexExampleApp());
    await tester.pumpAndSettle();
    tester.takeException(); // consume the intentional "Before" overflow.

    expect(find.textContaining('220px wide'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('220px wide'), findsNothing);
  });
}

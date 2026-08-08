import 'package:flutter_test/flutter_test.dart';
import 'package:safe_flex/safe_flex.dart';

void main() {
  group('OverflowStrategy', () {
    test('exposes exactly the five documented strategies', () {
      expect(OverflowStrategy.values, hasLength(5));
      expect(OverflowStrategy.values, <OverflowStrategy>[
        OverflowStrategy.scroll,
        OverflowStrategy.shrink,
        OverflowStrategy.wrap,
        OverflowStrategy.scale,
        OverflowStrategy.clip,
      ]);
    });

    test('each value has a stable, lowercase name used for logging', () {
      expect(OverflowStrategy.scroll.name, 'scroll');
      expect(OverflowStrategy.shrink.name, 'shrink');
      expect(OverflowStrategy.wrap.name, 'wrap');
      expect(OverflowStrategy.scale.name, 'scale');
      expect(OverflowStrategy.clip.name, 'clip');
    });

    test('values are distinct', () {
      expect(
        OverflowStrategy.values.toSet(),
        hasLength(OverflowStrategy.values.length),
      );
    });
  });
}

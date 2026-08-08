import 'package:flutter/widgets.dart';

import 'overflow_strategy.dart';
import 'safe_flex_widget.dart';

/// A drop-in replacement for [Column] that automatically prevents the
/// classic `RenderFlex overflowed by N pixels` error.
///
/// `SafeColumn(children: [...])` behaves exactly like
/// `Column(children: [...])` when its children fit the available height.
/// When they don't, it applies [strategy] instead of overflowing. See
/// [SafeFlex] for the full explanation of how overflow is detected and
/// handled, and [OverflowStrategy] for what each strategy does.
///
/// ```dart
/// SafeColumn(
///   strategy: OverflowStrategy.shrink,
///   children: [
///     Text(title, style: Theme.of(context).textTheme.headlineSmall),
///     Text(subtitle),
///     const SizedBox(height: 8),
///     ElevatedButton(onPressed: onTap, child: const Text('Continue')),
///   ],
/// )
/// ```
class SafeColumn extends StatelessWidget {
  /// Creates a [SafeColumn], a vertical [SafeFlex].
  const SafeColumn({
    super.key,
    required this.children,
    this.strategy = OverflowStrategy.scroll,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textBaseline,
    this.spacing = 0,
    this.debugLabel,
    this.onOverflow,
  });

  /// The widgets to lay out vertically, in order — identical in meaning to
  /// [Column.children].
  final List<Widget> children;

  /// The fallback layout applied when [children] don't fit the available
  /// height. Defaults to [OverflowStrategy.scroll].
  final OverflowStrategy strategy;

  /// How children are placed along the vertical axis when there is no
  /// overflow — identical in meaning to [Column.mainAxisAlignment].
  final MainAxisAlignment mainAxisAlignment;

  /// How much vertical space to occupy when there is no overflow —
  /// identical in meaning to [Column.mainAxisSize].
  final MainAxisSize mainAxisSize;

  /// How children are placed along the horizontal axis — identical in
  /// meaning to [Column.crossAxisAlignment].
  final CrossAxisAlignment crossAxisAlignment;

  /// The baseline to use when [crossAxisAlignment] is
  /// [CrossAxisAlignment.baseline] — identical in meaning to
  /// [Column.textBaseline]. Required in that case.
  final TextBaseline? textBaseline;

  /// Extra vertical space inserted between each pair of adjacent children,
  /// in logical pixels.
  final double spacing;

  /// An optional label used in debug-mode log messages when a fallback
  /// [strategy] is applied, so you can tell which [SafeColumn] in your
  /// widget tree triggered it.
  final String? debugLabel;

  /// Called once whenever this [SafeColumn] transitions from fitting its
  /// available height to overflowing it and applying [strategy] as a
  /// result.
  final SafeFlexOverflowCallback? onOverflow;

  @override
  Widget build(BuildContext context) {
    return SafeFlex(
      direction: Axis.vertical,
      strategy: strategy,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: textBaseline,
      spacing: spacing,
      debugLabel: debugLabel,
      onOverflow: onOverflow,
      children: children,
    );
  }
}

import 'package:flutter/widgets.dart';

import 'overflow_strategy.dart';
import 'safe_flex_widget.dart';

/// A drop-in replacement for [Row] that automatically prevents the classic
/// `RenderFlex overflowed by N pixels` error.
///
/// `SafeRow(children: [...])` behaves exactly like `Row(children: [...])`
/// when its children fit the available width. When they don't, it applies
/// [strategy] instead of overflowing. See [SafeFlex] for the full
/// explanation of how overflow is detected and handled, and
/// [OverflowStrategy] for what each strategy does.
///
/// ```dart
/// SafeRow(
///   strategy: OverflowStrategy.scroll,
///   children: [
///     Text(username, style: Theme.of(context).textTheme.titleMedium),
///     const SizedBox(width: 8),
///     const Badge(label: Text('PRO')),
///     const Icon(Icons.verified),
///   ],
/// )
/// ```
class SafeRow extends StatelessWidget {
  /// Creates a [SafeRow], a horizontal [SafeFlex].
  const SafeRow({
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

  /// The widgets to lay out horizontally, in order — identical in meaning
  /// to [Row.children].
  final List<Widget> children;

  /// The fallback layout applied when [children] don't fit the available
  /// width. Defaults to [OverflowStrategy.scroll].
  final OverflowStrategy strategy;

  /// How children are placed along the horizontal axis when there is no
  /// overflow — identical in meaning to [Row.mainAxisAlignment].
  final MainAxisAlignment mainAxisAlignment;

  /// How much horizontal space to occupy when there is no overflow —
  /// identical in meaning to [Row.mainAxisSize].
  final MainAxisSize mainAxisSize;

  /// How children are placed along the vertical axis — identical in
  /// meaning to [Row.crossAxisAlignment].
  final CrossAxisAlignment crossAxisAlignment;

  /// The baseline to use when [crossAxisAlignment] is
  /// [CrossAxisAlignment.baseline] — identical in meaning to
  /// [Row.textBaseline]. Required in that case.
  final TextBaseline? textBaseline;

  /// Extra horizontal space inserted between each pair of adjacent
  /// children, in logical pixels.
  final double spacing;

  /// An optional label used in debug-mode log messages when a fallback
  /// [strategy] is applied, so you can tell which [SafeRow] in your
  /// widget tree triggered it.
  final String? debugLabel;

  /// Called once whenever this [SafeRow] transitions from fitting its
  /// available width to overflowing it and applying [strategy] as a
  /// result.
  final SafeFlexOverflowCallback? onOverflow;

  @override
  Widget build(BuildContext context) {
    return SafeFlex(
      direction: Axis.horizontal,
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

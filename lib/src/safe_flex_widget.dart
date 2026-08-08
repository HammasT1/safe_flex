import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

import 'overflow_strategy.dart';
import 'safe_flex_render.dart';

/// Signature for [SafeFlex.onOverflow].
///
/// Called with the [OverflowStrategy] that was applied whenever a
/// [SafeFlex] transitions from fitting its available space to overflowing
/// it. Useful for analytics/telemetry, e.g. counting how often a
/// particular layout has to fall back so it can be redesigned.
typedef SafeFlexOverflowCallback = void Function(OverflowStrategy strategy);

/// A drop-in replacement for [Row] and [Column] that automatically
/// prevents the classic `RenderFlex overflowed by N pixels` error.
///
/// Flutter's [Row] and [Column] size their non-flexible children to their
/// natural ("intrinsic") size and simply overflow — painting content
/// outside their bounds and, in debug builds, drawing the familiar
/// yellow-and-black striped banner — whenever those children don't fit the
/// available space. This is one of the most common runtime layout issues
/// in Flutter apps, especially with dynamic text, user-generated content,
/// or varying screen sizes.
///
/// [SafeFlex] measures its children's natural size against the space
/// actually available and, only if they wouldn't fit, transparently swaps
/// in a fallback layout driven by [strategy] — before anything is ever
/// painted, so the overflow banner never appears, not even for a single
/// frame. When the content *does* fit, [SafeFlex] renders exactly like a
/// plain [Flex] (which [Row] and [Column] are themselves shorthand for),
/// so there is no visual difference and no performance cliff for the
/// common case.
///
/// ```dart
/// // Before: throws a RenderFlex overflow error if the username is long.
/// Row(
///   children: [
///     Text(username, style: Theme.of(context).textTheme.titleMedium),
///     const SizedBox(width: 8),
///     const Badge(label: Text('PRO')),
///     const Icon(Icons.verified),
///   ],
/// )
///
/// // After: automatically scrolls, shrinks, wraps, scales, or clips.
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
///
/// See also:
///
///  * [SafeRow], a shorthand for `SafeFlex(direction: Axis.horizontal)`.
///  * [SafeColumn], a shorthand for `SafeFlex(direction: Axis.vertical)`.
///  * [OverflowStrategy], the available fallback strategies.
class SafeFlex extends StatefulWidget {
  /// Creates a [SafeFlex].
  ///
  /// The [children] argument must not be null. [direction] defaults to
  /// [Axis.horizontal] (matching [Row]); use [SafeRow]/[SafeColumn] for a
  /// more familiar, direction-specific constructor.
  const SafeFlex({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.strategy = OverflowStrategy.scroll,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textBaseline,
    this.spacing = 0,
    this.debugLabel,
    this.onOverflow,
  });

  /// The widgets to lay out, in order — identical in meaning to
  /// [Flex.children].
  final List<Widget> children;

  /// The axis along which children are placed. [Axis.horizontal] behaves
  /// like [Row]; [Axis.vertical] behaves like [Column].
  final Axis direction;

  /// The fallback layout applied when [children] don't fit the available
  /// space along [direction]. Defaults to [OverflowStrategy.scroll].
  final OverflowStrategy strategy;

  /// How children are placed along the main axis when there is no
  /// overflow — identical in meaning to [Flex.mainAxisAlignment].
  final MainAxisAlignment mainAxisAlignment;

  /// How much space to occupy along the main axis when there is no
  /// overflow — identical in meaning to [Flex.mainAxisSize].
  final MainAxisSize mainAxisSize;

  /// How children are placed along the cross axis — identical in meaning
  /// to [Flex.crossAxisAlignment].
  final CrossAxisAlignment crossAxisAlignment;

  /// The baseline to use when [crossAxisAlignment] is
  /// [CrossAxisAlignment.baseline] — identical in meaning to
  /// [Flex.textBaseline]. Required in that case, exactly as it is for
  /// [Flex] itself.
  final TextBaseline? textBaseline;

  /// Extra space inserted between each pair of adjacent children, in
  /// logical pixels. Applied consistently across every [strategy].
  final double spacing;

  /// An optional label used in debug-mode log messages when a fallback
  /// [strategy] is applied, so you can tell which [SafeFlex] in your
  /// widget tree triggered it. Has no effect on layout and is stripped
  /// from release builds.
  final String? debugLabel;

  /// Called once whenever this [SafeFlex] transitions from fitting its
  /// available space to overflowing it and applying [strategy] as a
  /// result. Not called again while the overflow persists, and not called
  /// when there is no overflow. Useful for analytics or logging.
  final SafeFlexOverflowCallback? onOverflow;

  @override
  State<SafeFlex> createState() => _SafeFlexState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('direction', direction))
      ..add(EnumProperty<OverflowStrategy>('strategy', strategy))
      ..add(
        EnumProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment),
      )
      ..add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize))
      ..add(
        EnumProperty<CrossAxisAlignment>(
          'crossAxisAlignment',
          crossAxisAlignment,
        ),
      )
      ..add(
        EnumProperty<TextBaseline>(
          'textBaseline',
          textBaseline,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('spacing', spacing))
      ..add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }
}

class _SafeFlexState extends State<SafeFlex> {
  bool _isOverflowing = false;

  void _handleOverflowChanged(bool isOverflowing) {
    if (!mounted) return;

    if (isOverflowing) {
      assert(() {
        if (widget.debugLabel != null) {
          debugPrint(
            'SafeFlex(${widget.debugLabel}): content overflowed, '
            'applying OverflowStrategy.${widget.strategy.name}.',
          );
        }
        return true;
      }());
      widget.onOverflow?.call(widget.strategy);
    }

    if (isOverflowing != _isOverflowing) {
      setState(() => _isOverflowing = isOverflowing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> spacedChildren = _spaced(
      widget.children,
      widget.spacing,
      widget.direction,
    );

    final Widget content = _isOverflowing
        ? _buildFallback(spacedChildren)
        : Flex(
            direction: widget.direction,
            mainAxisAlignment: widget.mainAxisAlignment,
            mainAxisSize: widget.mainAxisSize,
            crossAxisAlignment: widget.crossAxisAlignment,
            textBaseline: widget.textBaseline,
            children: spacedChildren,
          );

    return OverflowReporter(
      axis: widget.direction,
      onOverflowChanged: _handleOverflowChanged,
      child: content,
    );
  }

  Widget _buildFallback(List<Widget> spacedChildren) {
    switch (widget.strategy) {
      case OverflowStrategy.scroll:
        return SingleChildScrollView(
          scrollDirection: widget.direction,
          child: Flex(
            direction: widget.direction,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.mainAxisAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            textBaseline: widget.textBaseline,
            children: spacedChildren,
          ),
        );

      case OverflowStrategy.shrink:
      case OverflowStrategy.scale:
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: _boxAlignment(widget.mainAxisAlignment, widget.direction),
          child: Flex(
            direction: widget.direction,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.mainAxisAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            textBaseline: widget.textBaseline,
            children: spacedChildren,
          ),
        );

      case OverflowStrategy.wrap:
        return Wrap(
          direction: widget.direction,
          alignment: _wrapAlignment(widget.mainAxisAlignment),
          crossAxisAlignment: _wrapCrossAlignment(widget.crossAxisAlignment),
          spacing: widget.spacing,
          runSpacing: widget.spacing,
          children: widget.children,
        );

      case OverflowStrategy.clip:
        return ClipRect(
          child: OverflowBox(
            alignment: _boxAlignment(
              widget.mainAxisAlignment,
              widget.direction,
            ),
            // Without this, OverflowBox's default fit (size itself to "as
            // large as the parent allows") throws an infinite-size layout
            // error whenever the incoming constraint has an unbounded
            // dimension — e.g. a horizontal SafeRow inside a Column, where
            // height is naturally unconstrained. Deferring to the child's
            // own (finite) size avoids that entirely.
            fit: OverflowBoxFit.deferToChild,
            minWidth: 0,
            minHeight: 0,
            maxWidth: widget.direction == Axis.horizontal
                ? double.infinity
                : null,
            maxHeight: widget.direction == Axis.vertical
                ? double.infinity
                : null,
            child: Flex(
              direction: widget.direction,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: widget.mainAxisAlignment,
              crossAxisAlignment: widget.crossAxisAlignment,
              textBaseline: widget.textBaseline,
              children: spacedChildren,
            ),
          ),
        );
    }
  }
}

List<Widget> _spaced(List<Widget> children, double spacing, Axis direction) {
  if (spacing <= 0 || children.length < 2) return children;
  final List<Widget> result = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    if (i > 0) {
      result.add(
        direction == Axis.horizontal
            ? SizedBox(width: spacing)
            : SizedBox(height: spacing),
      );
    }
    result.add(children[i]);
  }
  return result;
}

Alignment _boxAlignment(MainAxisAlignment mainAxisAlignment, Axis direction) {
  final bool horizontal = direction == Axis.horizontal;
  switch (mainAxisAlignment) {
    case MainAxisAlignment.start:
      return horizontal ? Alignment.centerLeft : Alignment.topCenter;
    case MainAxisAlignment.end:
      return horizontal ? Alignment.centerRight : Alignment.bottomCenter;
    case MainAxisAlignment.center:
    case MainAxisAlignment.spaceBetween:
    case MainAxisAlignment.spaceAround:
    case MainAxisAlignment.spaceEvenly:
      return Alignment.center;
  }
}

WrapAlignment _wrapAlignment(MainAxisAlignment value) {
  switch (value) {
    case MainAxisAlignment.start:
      return WrapAlignment.start;
    case MainAxisAlignment.end:
      return WrapAlignment.end;
    case MainAxisAlignment.center:
      return WrapAlignment.center;
    case MainAxisAlignment.spaceBetween:
      return WrapAlignment.spaceBetween;
    case MainAxisAlignment.spaceAround:
      return WrapAlignment.spaceAround;
    case MainAxisAlignment.spaceEvenly:
      return WrapAlignment.spaceEvenly;
  }
}

WrapCrossAlignment _wrapCrossAlignment(CrossAxisAlignment value) {
  switch (value) {
    case CrossAxisAlignment.start:
      return WrapCrossAlignment.start;
    case CrossAxisAlignment.end:
      return WrapCrossAlignment.end;
    case CrossAxisAlignment.center:
      return WrapCrossAlignment.center;
    case CrossAxisAlignment.stretch:
    case CrossAxisAlignment.baseline:
      return WrapCrossAlignment.start;
  }
}

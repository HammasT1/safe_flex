// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Signature for the callback [RenderOverflowReporter] uses to report a
/// change in its overflow state.
///
/// Called with `true` the moment the wrapped child's natural size stops
/// fitting the available space, and with `false` when it fits again.
typedef OverflowChangedCallback = void Function(bool isOverflowing);

/// Wraps whichever widget [SafeFlex] currently has mounted — the plain
/// `Flex` when its children fit, or the active [OverflowStrategy]'s widget
/// tree when they don't — and measures, on every layout pass, whether the
/// content's *natural* size still fits the available space.
///
/// [SafeFlex] keeps exactly one content subtree mounted at a time (unlike
/// an approach that lays out both a primary and a fallback subtree
/// simultaneously), so children are only ever built once — this matters
/// because Flutter widgets may carry a [GlobalKey] or hold [State], and
/// building the same child twice would either crash (duplicate
/// [GlobalKey]) or silently duplicate that state (e.g. a `Timer` started
/// in `initState`).
///
/// Because the swap to a fallback strategy only happens on the *next*
/// frame after overflow is first measured (a build must occur to change
/// which widget is mounted), this render object also suppresses painting
/// for the one transitional frame where the still-mounted plain `Flex`
/// has just been found to overflow — so Flutter's debug-mode
/// yellow-and-black overflow banner never has a chance to render, even
/// for a single frame. On the following frame, [SafeFlex] has already
/// rebuilt with the fallback content, which never overflows itself.
///
/// This widget is an internal implementation detail of `safe_flex` and is
/// not exported from the package's public API.
class OverflowReporter extends SingleChildRenderObjectWidget {
  /// Creates an [OverflowReporter].
  const OverflowReporter({
    super.key,
    required this.axis,
    required this.onOverflowChanged,
    required Widget super.child,
  });

  /// The main axis along which overflow is measured — [Axis.horizontal]
  /// for row-like content, [Axis.vertical] for column-like content.
  final Axis axis;

  /// Invoked whenever the overflow state changes.
  final OverflowChangedCallback onOverflowChanged;

  @override
  RenderOverflowReporter createRenderObject(BuildContext context) {
    return RenderOverflowReporter(
      axis: axis,
      onOverflowChanged: onOverflowChanged,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOverflowReporter renderObject,
  ) {
    renderObject
      ..axis = axis
      ..onOverflowChanged = onOverflowChanged;
  }
}

/// The [RenderObject] backing [OverflowReporter].
///
/// Behaves exactly like a transparent [RenderProxyBox] — laying out and
/// painting its single child unchanged — except that it additionally:
///
/// 1. Measures the child's *natural* (unconstrained) main-axis extent
///    using [RenderBox.getMaxIntrinsicWidth] / [RenderBox.getMaxIntrinsicHeight]
///    after every layout. This is a pure measurement query; it never
///    triggers a second, overflow-producing layout pass.
/// 2. Compares that natural extent against the available space in
///    [RenderObject.constraints] and reports transitions via
///    [OverflowReporter.onOverflowChanged].
/// 3. Skips painting for exactly the one frame where the child transitions
///    from fitting to overflowing, since that frame's child is still the
///    (about to be replaced) plain `Flex`, whose own [RenderBox.paint]
///    would otherwise draw Flutter's debug overflow indicator.
class RenderOverflowReporter extends RenderProxyBox {
  /// Creates a [RenderOverflowReporter].
  RenderOverflowReporter({
    required Axis axis,
    required OverflowChangedCallback onOverflowChanged,
  }) : _axis = axis,
       _onOverflowChanged = onOverflowChanged;

  Axis _axis;

  /// The main axis along which overflow is measured.
  Axis get axis => _axis;
  set axis(Axis value) {
    if (_axis == value) return;
    _axis = value;
    markNeedsLayout();
  }

  OverflowChangedCallback _onOverflowChanged;

  /// The callback invoked when the overflow state changes.
  set onOverflowChanged(OverflowChangedCallback value) =>
      _onOverflowChanged = value;

  bool _isOverflowing = false;

  /// Whether the wrapped child's natural size currently exceeds the
  /// available space.
  bool get isOverflowing => _isOverflowing;

  bool _suppressNextPaint = false;

  bool get _horizontal => _axis == Axis.horizontal;

  @override
  void performLayout() {
    super.performLayout();

    bool overflowing = false;
    final RenderBox? c = child;
    if (c != null) {
      final double available = _horizontal
          ? constraints.maxWidth
          : constraints.maxHeight;
      if (available.isFinite) {
        final double crossHint = _horizontal
            ? (constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : double.infinity)
            : (constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : double.infinity);
        final double natural = _horizontal
            ? c.getMaxIntrinsicWidth(crossHint)
            : c.getMaxIntrinsicHeight(crossHint);
        overflowing = natural > available + precisionErrorTolerance;
      }
    }

    _suppressNextPaint = overflowing && !_isOverflowing;

    if (overflowing != _isOverflowing) {
      _isOverflowing = overflowing;
      final OverflowChangedCallback callback = _onOverflowChanged;
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => callback(overflowing),
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_suppressNextPaint) return;
    super.paint(context, offset);
  }
}

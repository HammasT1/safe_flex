/// The strategies [SafeFlex] can apply to keep a `Row`- or `Column`-like
/// layout from overflowing its available space.
///
/// Each strategy makes a different trade-off between preserving the
/// original layout, keeping content fully visible, and readability. Pick
/// the one that best fits the UI you're building — see the package
/// README's strategy comparison table for a side-by-side overview, or run
/// the `example/` app to see all five applied to the same overflowing row.
enum OverflowStrategy {
  /// Wraps the content in a scrollable view along the flex's main axis
  /// once it would overflow, so the user can scroll to see the rest.
  ///
  /// Nothing is hidden, shrunk, or clipped — this is the safest strategy
  /// when every child must remain fully visible and interactive.
  ///
  /// Best for: horizontal lists of filter chips, tab bars, toolbars.
  scroll,

  /// Wraps the content in a box that scales it down uniformly (preserving
  /// aspect ratio) until it fits the available space.
  ///
  /// All children shrink together as a single unit, so relative
  /// proportions between them are preserved.
  ///
  /// Best for: compact rows such as stat pills or badge clusters where
  /// slightly smaller content beats scrolling or wrapping.
  shrink,

  /// Falls back to a wrapping (multi-line) layout, moving children that
  /// don't fit onto a new line (or new column, for a vertical
  /// [SafeFlex]) instead of overflowing.
  ///
  /// Best for: tag lists, chip groups, and toolbars where reflowing
  /// across multiple lines is acceptable.
  wrap,

  /// Uniformly scales the content down until it fits, identically to
  /// [shrink].
  ///
  /// Kept as its own named option so call sites that are specifically
  /// addressing text/label-heavy overflow can express that intent in
  /// code, even though the underlying mechanism (scale-to-fit) is shared
  /// with [shrink]. Flutter has no reliable, generic way to resize *only*
  /// the text within arbitrary child widgets, so both options use the
  /// same safe, uniform scaling implementation.
  ///
  /// Best for: rows dominated by text/labels where proportionally
  /// shrinking everything down is the most natural fix.
  scale,

  /// Clips overflowing content at the boundary instead of letting it
  /// paint outside the available space or trigger the debug-mode
  /// overflow banner.
  ///
  /// Content past the edge is simply not drawn. This is a low-surprise,
  /// "do no harm" fallback appropriate for production when neither
  /// scrolling nor shrinking makes sense for the layout.
  ///
  /// Best for: a last-resort safety net in production UI, e.g. as the
  /// [SafeFlex.strategy] deep inside a widget you don't fully control.
  clip,
}

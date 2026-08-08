/// A drop-in replacement for [Row] and [Column] that automatically
/// prevents the classic `RenderFlex overflowed by N pixels` error using
/// configurable strategies (`scroll`, `shrink`, `wrap`, `scale`, `clip`).
///
/// Import this library to use [SafeFlex], [SafeRow], [SafeColumn], and
/// [OverflowStrategy]:
///
/// ```dart
/// import 'package:safe_flex/safe_flex.dart';
/// ```
library;

// ignore: unused_import
import 'package:flutter/widgets.dart' show Row, Column;

export 'src/overflow_strategy.dart';
export 'src/safe_column.dart';
export 'src/safe_flex_widget.dart' show SafeFlex, SafeFlexOverflowCallback;
export 'src/safe_row.dart';

## 0.0.1

Initial release.

- Added `SafeFlex`, a drop-in replacement for `Flex` that automatically prevents `RenderFlex` overflow errors by measuring children's natural size and, only if they wouldn't fit, swapping in a fallback layout before anything is painted.
- Added `SafeRow` and `SafeColumn` convenience widgets for `Axis.horizontal` and `Axis.vertical`.
- Added `OverflowStrategy` with five fallback strategies: `scroll`, `shrink`, `wrap`, `scale`, and `clip`.
- Added `debugLabel` for identifying which `SafeFlex` triggered a fallback in debug logs.
- Added `onOverflow` callback for analytics/telemetry hooks.
- Zero dependencies beyond the Flutter SDK.

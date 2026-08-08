# safe_flex

[![pub package](https://img.shields.io/pub/v/safe_flex.svg)](https://pub.dev/packages/safe_flex)
[![likes](https://img.shields.io/pub/likes/safe_flex?logo=dart)](https://pub.dev/packages/safe_flex/score)
[![points](https://img.shields.io/pub/points/safe_flex?logo=dart)](https://pub.dev/packages/safe_flex/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20windows%20%7C%20macos%20%7C%20linux-4DB6E5)](#-platform-support)

🛡️ A drop-in replacement for `Row` and `Column` that automatically **prevents the classic `RenderFlex overflowed by N pixels` error** — instead of making you wrap every child in `Expanded`/`Flexible`, or discover the yellow-and-black striped banner in production.

## 📚 Table of contents

- [The problem](#-the-problem)
- [Before / after](#-before--after)
- [How it avoids the flash of the overflow banner](#-how-it-avoids-the-flash-of-the-overflow-banner)
- [Strategy comparison](#-strategy-comparison)
- [Platform support](#-platform-support)
- [Installation](#-installation)
- [Usage](#-usage)
- [API surface](#-api-surface)
- [Example app](#-example-app)
- [Demo](#-demo)
- [FAQ](#-faq)
- [Limitations](#-limitations)
- [Contributing](#-contributing)
- [License](#-license)

## 🧨 The problem

If you've built anything in Flutter, you've seen this:

```
A RenderFlex overflowed by 12 pixels on the right.
```

...followed by a yellow-and-black striped banner painted right over your UI. It happens the moment a `Row` or `Column`'s children need more space than is actually available — a long username, a localized string that's longer in German than in English, a badge that wasn't there in your design mockup, a phone that's narrower than the one you tested on. `Row` and `Column` size their children to their natural size and simply overflow when that doesn't fit; they don't degrade gracefully on their own.

The usual fix is to manually audit every `Row`/`Column` in your app and wrap the right child in `Expanded`, `Flexible`, or a `SingleChildScrollView` — one at a time, forever, as new content ships. **`safe_flex` does this automatically.** ✅

## 🔁 Before / after

```dart
// ❌ Before: throws a RenderFlex overflow error if the username is long.
Row(
  children: [
    Text(username, style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(width: 8),
    const Badge(label: Text('PRO')),
    const Icon(Icons.verified),
  ],
)
```

```dart
// ✅ After: automatically scrolls, shrinks, wraps, scales, or clips —
// whichever strategy you choose — instead of overflowing.
SafeRow(
  strategy: OverflowStrategy.scroll,
  children: [
    Text(username, style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(width: 8),
    const Badge(label: Text('PRO')),
    const Icon(Icons.verified),
  ],
)
```

That's it — swap `Row` for `SafeRow` (or `Column` for `SafeColumn`), keep the same constructor arguments (`mainAxisAlignment`, `crossAxisAlignment`, `children`, ...), and pick a strategy.

## ⚙️ How it avoids the flash of the overflow banner

`SafeFlex` measures its children's *natural* size against the space that's actually available using Flutter's intrinsic-size APIs — no `LayoutBuilder` guesswork, no catching `FlutterError`. When they fit, it renders exactly like a plain `Flex` (which `Row` and `Column` are themselves shorthand for), so there's no visual difference and no performance cliff for the common case. When they don't fit, it swaps in the fallback strategy's widget tree *before that frame is painted*, so Flutter's debug-mode overflow indicator never has a chance to render — not even for a single frame.

## 📊 Strategy comparison

| Strategy | What it does | Best for |
|---|---|---|
| 🔃 `OverflowStrategy.scroll` *(default)* | Wraps the content in a scrollable view along the main axis. Nothing is hidden or shrunk. | Filter chips, tab bars, toolbars — anywhere every item must stay fully visible and interactive. |
| 🤏 `OverflowStrategy.shrink` | Scales the whole row/column down uniformly (via `FittedBox`) until it fits. | Compact rows like stat pills or badge clusters. |
| ↩️ `OverflowStrategy.wrap` | Falls back to a `Wrap` layout, reflowing overflowing children onto a new line. | Tag lists, chip groups, toolbars where multiple lines are fine. |
| 🔍 `OverflowStrategy.scale` | Identical mechanism to `shrink` — scales content down until it fits. Named separately for call sites specifically addressing text-heavy overflow. | Rows dominated by text/labels. |
| ✂️ `OverflowStrategy.clip` | Clips overflowing content at the boundary instead of drawing outside it. | A safe, low-surprise last resort in production UI. |

## 📱 Platform support

`safe_flex` is pure Dart/Flutter widget and rendering code — no platform channels, no `dart:io`, no native dependencies. It works identically everywhere Flutter runs:

| Android | iOS | Web | Windows | macOS | Linux |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## 📦 Installation

Add `safe_flex` to your `pubspec.yaml`:

```yaml
dependencies:
  safe_flex: ^0.0.1
```

Then import it:

```dart
import 'package:safe_flex/safe_flex.dart';
```

## 🚀 Usage

```dart
import 'package:flutter/material.dart';
import 'package:safe_flex/safe_flex.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return SafeRow(
      strategy: OverflowStrategy.scroll,
      spacing: 8,
      debugLabel: 'profile-header', // shown in debug logs if it overflows
      onOverflow: (strategy) => analytics.logOverflow('profile-header', strategy),
      children: [
        Text(username, style: Theme.of(context).textTheme.titleMedium),
        const Badge(label: Text('PRO')),
        const Icon(Icons.verified),
      ],
    );
  }
}
```

`SafeColumn` works the same way for vertical layouts. Both are thin wrappers around `SafeFlex`, which accepts a `direction` if you'd rather use one widget for both axes.

## 🧾 API surface

`SafeFlex` / `SafeRow` / `SafeColumn` accept the same core arguments as `Flex` / `Row` / `Column` — `children`, `mainAxisAlignment`, `mainAxisSize`, `crossAxisAlignment`, `textBaseline` — plus:

| Parameter | Type | Description |
|---|---|---|
| `strategy` | `OverflowStrategy` | The fallback applied when content overflows. Default: `scroll`. |
| `spacing` | `double` | A fixed gap inserted between every pair of children, so you don't need manual `SizedBox` spacers. |
| `debugLabel` | `String?` | An optional name printed in debug-mode logs when a fallback strategy engages, so you can tell which `SafeFlex` in a large widget tree triggered it. Stripped entirely from release builds. |
| `onOverflow` | `void Function(OverflowStrategy)?` | Called once per overflow *event* (not once per frame) — useful for analytics or logging which layouts are running out of room in the wild. |

## 🎮 Example app

The [`example/`](example) app renders the same overflow-prone row (a long username, a badge, and an icon) once as a plain `Row` and once per `OverflowStrategy`, all inside a card whose width you can drag with a slider — a live, simulated-device-width preview so you can see every strategy adapt in real time.

```sh
cd example
flutter run
```

## 🎬 Demo

![Demo of the width slider dragging across the five SafeRow strategy cards](doc/demo.gif)

## ❓ FAQ

<details>
<summary><b>Does this replace <code>Expanded</code> and <code>Flexible</code>?</b></summary>

For the classic overflow scenario — a row of plain, non-flexible content like text, icons, and badges — yes, that's exactly the point. `safe_flex` isn't meant to replace `Expanded`/`Flexible` in layouts that are already deliberately using flex factors to divide space; it's meant to remove the need to reach for them just to stop an overflow error.
</details>

<details>
<summary><b>Does it add any runtime dependencies?</b></summary>

No. `safe_flex` depends on nothing beyond the Flutter SDK itself — no third-party packages, no native code.
</details>

<details>
<summary><b>Will it hide bugs by silently absorbing overflow everywhere?</b></summary>

`onOverflow` and `debugLabel` exist specifically so overflow isn't invisible — you can log every occurrence in debug builds or pipe it to analytics in production, so a `safe_flex`-wrapped layout that's *frequently* overflowing is still visible to you as a signal worth fixing at the design level, even though users never see a broken screen.
</details>

<details>
<summary><b>Does <code>scale</code> shrink only the text, or everything?</b></summary>

Everything, uniformly — the whole row/column is scaled down as one unit via `FittedBox`. Flutter has no reliable, generic way to resize *only* the text within arbitrary child widgets, so `shrink` and `scale` intentionally share this same, safe implementation.
</details>

## ⚠️ Limitations

- Overflow detection relies on Flutter's intrinsic-size APIs, which most common widgets (`Text`, `Icon`, `Container`, ...) support well. A handful of widgets (notably lazy, viewport-based ones like `ListView`) don't implement intrinsics and aren't good candidates as direct `SafeFlex` children.
- `SafeFlex` is designed for the classic case of plain, non-flexible children (text, icons, badges) — the case that causes overflow in the first place. It doesn't need `Expanded`/`Flexible` children, since that's exactly what it replaces.

## 🤝 Contributing

Issues and pull requests are welcome at the [GitHub repository](https://github.com/HammasT1/safe_flex). 🙌

## 📄 License

MIT © Muhammad Hammas Rasheed — see [LICENSE](LICENSE).

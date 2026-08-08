import 'package:flutter/material.dart';
import 'package:safe_flex/safe_flex.dart';

void main() => runApp(const SafeFlexExampleApp());

/// Demo app for the `safe_flex` package.
///
/// Shows the same overflow-prone layout — a long username, a "PRO" badge,
/// and a verified icon — rendered with a plain [Row] (which overflows) and
/// then with a [SafeRow] for each [OverflowStrategy], all constrained to a
/// simulated device width you can drag to see them adapt live.
class SafeFlexExampleApp extends StatelessWidget {
  const SafeFlexExampleApp({super.key});

  static const _seed = Color(0xFF3D5AFE);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seed);
    return MaterialApp(
      title: 'safe_flex demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
      home: const OverflowDemoPage(),
    );
  }
}

/// Per-[OverflowStrategy] presentation: a distinguishing color, icon, and a
/// short human-readable explanation for the demo cards.
class _StrategyPresentation {
  const _StrategyPresentation({
    required this.color,
    required this.icon,
    required this.description,
  });

  final Color color;
  final IconData icon;
  final String description;
}

const Map<OverflowStrategy, _StrategyPresentation> _presentations = {
  OverflowStrategy.scroll: _StrategyPresentation(
    color: Color(0xFF2979FF),
    icon: Icons.swap_horiz_rounded,
    description:
        'Wraps the row in a horizontally scrollable view once it overflows.',
  ),
  OverflowStrategy.shrink: _StrategyPresentation(
    color: Color(0xFF7C4DFF),
    icon: Icons.compress_rounded,
    description:
        'Scales the whole row down uniformly (via FittedBox) until it fits.',
  ),
  OverflowStrategy.wrap: _StrategyPresentation(
    color: Color(0xFF00BFA5),
    icon: Icons.wrap_text_rounded,
    description:
        'Reflows overflowing children onto a new line instead of overflowing.',
  ),
  OverflowStrategy.scale: _StrategyPresentation(
    color: Color(0xFF3D5AFE),
    icon: Icons.photo_size_select_small_rounded,
    description:
        'Identical mechanism to shrink — scales the row down until it fits.',
  ),
  OverflowStrategy.clip: _StrategyPresentation(
    color: Color(0xFFFF6D00),
    icon: Icons.content_cut_rounded,
    description:
        'Clips overflowing content at the boundary — a safe, low-surprise fallback.',
  ),
};

/// The demo's single screen: a width control at the top and a scrollable
/// list of strategy demonstrations below.
class OverflowDemoPage extends StatefulWidget {
  const OverflowDemoPage({super.key});

  @override
  State<OverflowDemoPage> createState() => _OverflowDemoPageState();
}

class _OverflowDemoPageState extends State<OverflowDemoPage> {
  static const double _minWidth = 140;
  static const double _maxWidth = 420;

  double _previewWidth = 220;
  int _overflowEvents = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.view_column_rounded,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'safe_flex',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Text(
              'demo',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _ControlPanel(
            width: _previewWidth,
            min: _minWidth,
            max: _maxWidth,
            overflowEvents: _overflowEvents,
            onChanged: (value) => setState(() => _previewWidth = value),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _DemoCard(
                  title: 'Before — plain Row',
                  description:
                      'A plain Row overflows once the username no longer fits: it paints outside its '
                      'bounds and, in debug builds, shows the classic yellow-and-black striped banner.',
                  width: _previewWidth,
                  accentColor: theme.colorScheme.error,
                  icon: Icons.warning_amber_rounded,
                  child: const Row(children: _demoChildren),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'After — SafeRow, one strategy per card',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final strategy in OverflowStrategy.values) ...[
                  _DemoCard(
                    title: 'OverflowStrategy.${strategy.name}',
                    description: _presentations[strategy]!.description,
                    width: _previewWidth,
                    accentColor: _presentations[strategy]!.color,
                    icon: _presentations[strategy]!.icon,
                    child: SafeRow(
                      strategy: strategy,
                      debugLabel: strategy.name,
                      onOverflow: (_) => setState(() => _overflowEvents++),
                      children: _demoChildren,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The overflow-prone content reused by every demo card: a long username,
/// a "PRO" badge, and a verified icon — the classic overflow scenario.
const List<Widget> _demoChildren = [
  Text(
    'alexandra.montgomery-whitfield',
    style: TextStyle(fontWeight: FontWeight.w600),
  ),
  SizedBox(width: 8),
  _ProBadge(),
  SizedBox(width: 6),
  Icon(Icons.verified, color: Colors.blue, size: 20),
];

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade600, Colors.orange.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// A card that pins [child] inside a box exactly [width] logical pixels
/// wide — the "simulated device width" — with a visible border so the
/// available space is obvious, alongside a title, icon, and description.
class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.description,
    required this.width,
    required this.accentColor,
    required this.icon,
    required this.child,
  });

  final String title;
  final String description;
  final double width;
  final Color accentColor;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      // A left Border (rather than a separate stretched Container inside an
      // IntrinsicHeight+Row) draws the same accent stripe without requiring
      // an intrinsic-height pre-measurement of the card's content — which,
      // for width-sensitive content like OverflowStrategy.wrap's multi-line
      // reflow, could otherwise mismatch the real layout for a frame during
      // rapid resizing (e.g. dragging the width slider) and overflow.
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor, width: 4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            // LayoutBuilder clamps the requested preview width to whatever
            // room is actually available, so dragging the slider past the
            // real screen width can never overflow the card itself — only
            // the SafeRow inside it, which is precisely what each card is
            // demonstrating a fix for.
            LayoutBuilder(
              builder: (context, constraints) {
                final double boxWidth = width < constraints.maxWidth
                    ? width
                    : constraints.maxWidth;
                return Container(
                  width: boxWidth,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRect(child: child),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The top control panel: a slider that lets the user simulate different
/// screen widths, plus live stats on the current width and how many
/// overflow events the strategy cards below have reported.
class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.width,
    required this.min,
    required this.max,
    required this.overflowEvents,
    required this.onChanged,
  });

  final double width;
  final double min;
  final double max;
  final int overflowEvents;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smartphone_rounded,
                size: 18,
                color: theme.colorScheme.outline,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 3),
                  child: Slider(
                    value: width,
                    min: min,
                    max: max,
                    divisions: ((max - min) / 10).round(),
                    label: '${width.round()}px',
                    onChanged: onChanged,
                  ),
                ),
              ),
              Icon(
                Icons.tablet_mac_rounded,
                size: 22,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                icon: Icons.straighten_rounded,
                label: '${width.round()}px wide',
                color: theme.colorScheme.primary,
              ),
              _StatChip(
                icon: Icons.report_gmailerrorred_rounded,
                label:
                    '$overflowEvents overflow event${overflowEvents == 1 ? '' : 's'}',
                color: overflowEvents > 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

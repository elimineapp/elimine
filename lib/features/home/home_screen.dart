import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/motion/container_transform.dart';
import '../../app/motion/motion.dart';
import '../../app/providers.dart';
import '../../core/appearance.dart';
import '../../core/db/queries.dart';
import '../../core/l10n/format.dart';
import '../analytics/analytics.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/intake_tile.dart';
import '../../widgets/substance_badge.dart';

/// Requests to scroll Home back to the top, counted so that every request
/// is a change: reselecting "Home" in the bottom navigation bar.
class HomeScrollToTop extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final homeScrollToTopProvider = NotifierProvider<HomeScrollToTop, int>(
  HomeScrollToTop.new,
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  /// Whether the user's last scroll went up, toward the top.
  bool _scrollingUp = false;

  bool _showBackToTop = false;

  /// How many screens down "Back to top" starts to show.
  static const _backToTopScreens = 2;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _scrollingUp = notification.direction == ScrollDirection.forward;
    }
    final metrics = notification.metrics;
    final show =
        _scrollingUp &&
        metrics.pixels > _backToTopScreens * metrics.viewportDimension;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);
    return false;
  }

  void _toTop() {
    setState(() {
      _scrollingUp = false;
      _showBackToTop = false;
    });
    if (!_scroll.hasClients || _scroll.offset <= 0) return;
    if (Motion.reducedOf(context)) {
      _scroll.jumpTo(0);
      return;
    }
    // Longer for longer ways, but never a slow crawl through the feed.
    final ms = (250 + _scroll.offset / 20).clamp(250, 600).round();
    _scroll.animateTo(
      0,
      duration: Duration(milliseconds: ms),
      curve: Motion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final substances = ref.watch(substancesProvider);
    final history = ref.watch(historyProvider);
    final limit = ref.watch(historyLimitProvider);
    final archived = ref.watch(archivedSubstancesProvider).value ?? const [];
    final marks = ref.watch(weekMarksProvider);
    final today = DateFormat.MMMMEEEEd(l.localeName).format(DateTime.now());

    ref.listen(homeScrollToTopProvider, (_, _) => _toTop());

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.appTitle),
            Text(
              toBeginningOfSentenceCase(today),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _BackToTop(
        visible: _showBackToTop,
        onPressed: _toTop,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            switch (substances) {
              AsyncData(value: final items) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    _SubstanceList(items: items, marks: marks),
                    const SliverToBoxAdapter(child: _NewSubstanceTile()),
                  ],
                ),
              ),
              AsyncError(:final error) => SliverToBoxAdapter(
                child: _Message('$error'),
              ),
              _ => const SliverToBoxAdapter(child: LinearProgressIndicator()),
            },
            // Above the endless feed, so it stays in reach; quiet, as it is
            // out of the daily path.
            if (archived.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    key: const Key('archiveEntry'),
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(l.archiveEntry(archived.length)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/archive'),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  archived.isNotEmpty ? 16 : 24,
                  16,
                  4,
                ),
                child: Text(l.historyTitle, style: theme.textTheme.titleMedium),
              ),
            ),
            // From the last value while the next page loads, so the feed
            // neither blanks nor loses its place.
            switch (history.value) {
              final items? when items.isEmpty => SliverToBoxAdapter(
                child: _Message(l.emptyIntakes),
              ),
              final items? => SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  if (i >= items.length - 10 && items.length >= limit) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ref.read(historyLimitProvider.notifier).more(limit);
                      }
                    });
                  }
                  final (:intake, :substance) = items[i];
                  return IntakeTile(
                    intake: intake,
                    unit: substance.unit,
                    title: substance.name,
                    leading: SubstanceBadge(
                      color: substance.color,
                      icon: substance.icon,
                    ),
                  );
                },
              ),
              null when history.hasError => SliverToBoxAdapter(
                child: _Message('${history.error}'),
              ),
              null => const SliverToBoxAdapter(child: SizedBox.shrink()),
            },
            // Room for "Back to top" over the last entry.
            const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
          ],
        ),
      ),
    );
  }
}

/// A small button that takes Home back to the top, shown only while the user
/// heads up from far down the feed.
class _BackToTop extends StatelessWidget {
  const _BackToTop({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reduced = Motion.reducedOf(context);
    final button = FloatingActionButton.small(
      key: const Key('backToTop'),
      heroTag: null,
      tooltip: l.backToTop,
      onPressed: onPressed,
      child: const Icon(Icons.arrow_upward),
    );
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Motion.short,
          curve: Motion.standard,
          child: reduced
              ? button
              : AnimatedScale(
                  scale: visible ? 1 : 0.6,
                  duration: Motion.short,
                  curve: Motion.standard,
                  child: button,
                ),
        ),
      ),
    );
  }
}

/// Substance tiles in the user's order, moved by long-press and drag (or the
/// screen reader's move actions).
class _SubstanceList extends ConsumerStatefulWidget {
  const _SubstanceList({required this.items, required this.marks});

  final List<SubstanceWithLast> items;
  final Map<String, List<int>> marks;

  @override
  ConsumerState<_SubstanceList> createState() => _SubstanceListState();
}

class _SubstanceListState extends ConsumerState<_SubstanceList> {
  /// The order on screen. It changes as soon as a tile is dropped, so the tile
  /// stays put until the database emits the saved order.
  late List<SubstanceWithLast> _items = widget.items;

  /// Index the dragged tile was picked up at; database updates wait until it
  /// is dropped.
  int? _dragFrom;

  static const _gap = 8.0;
  static const _radius = 20.0;

  @override
  void didUpdateWidget(_SubstanceList old) {
    super.didUpdateWidget(old);
    if (_dragFrom == null && !identical(widget.items, old.items)) {
      _items = widget.items;
    }
  }

  void _start(int index) {
    HapticFeedback.mediumImpact();
    _dragFrom = index;
  }

  /// Dropped where it was picked up: [_reorder] will not be called.
  void _end(int insertIndex) {
    final from = _dragFrom;
    if (from == null || insertIndex == from || insertIndex == from + 1) {
      setState(() {
        _dragFrom = null;
        _items = widget.items;
      });
    }
  }

  /// [to] is the index after removing the tile from [from].
  void _reorder(int from, int to) {
    final items = [..._items];
    final moved = items.removeAt(from);
    items.insert(to, moved);
    setState(() {
      _dragFrom = null;
      _items = items;
    });
    ref
        .read(substanceServiceProvider)
        .move(
          moved.substance.id,
          beforeId: to + 1 < items.length ? items[to + 1].substance.id : null,
        );
  }

  Widget _tile(int index) => _SubstanceTile(
    item: _items[index],
    weeks: widget.marks[_items[index].substance.id] ?? noWeekMarks,
  );

  /// The tile under the finger: lifted off the list on an opaque surface, so
  /// its tint does not show the tiles beneath.
  Widget _lifted(Widget child, int index, Animation<double> animation) =>
      AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = Curves.easeOut.transform(animation.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: Transform.scale(
              scale: 1 + 0.03 * t,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 6 * t,
                borderRadius: BorderRadius.circular(_radius),
                child: _tile(index),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) => SliverReorderableList(
    itemCount: _items.length,
    onReorderStart: _start,
    onReorderEnd: _end,
    onReorderItem: _reorder,
    proxyDecorator: _lifted,
    itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
      key: ValueKey(_items[i].substance.id),
      index: i,
      child: Padding(
        padding: const EdgeInsets.only(bottom: _gap),
        child: _tile(i),
      ),
    ),
  );
}

/// A substance in its color: icon, name, last intake and the weeks it was
/// taken in.
class _SubstanceTile extends ConsumerWidget {
  const _SubstanceTile({required this.item, required this.weeks});

  final SubstanceWithLast item;

  /// Intakes in each of the [markedWeeks] weeks, oldest first.
  final List<int> weeks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (:substance, :last) = item;
    // Rebuilt every minute, so the time since the last intake stays current.
    ref.watch(minuteTickProvider);
    final now = ref.watch(clockProvider)();
    final color = context.substanceColorOf(substance.color);
    final dark = theme.brightness == Brightness.dark;
    final lastLabel = l.lastIntake(last, substance.unit, now);

    return Material(
      color: color.withValues(alpha: dark ? 0.22 : 0.14),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/substance/${substance.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            spacing: 14,
            children: [
              SubstanceIconHero(
                tag: substanceIconTag(substance.id),
                child: SubstanceBadge(
                  color: substance.color,
                  icon: substance.icon,
                  filled: true,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      substance.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _WeekStrip(
                      weeks: weeks,
                      color: color,
                      empty: theme.colorScheme.outlineVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One rounded mark per week, in [color] when the substance was taken that
/// week: faint for one intake, stronger for two, full for three or more.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.weeks,
    required this.color,
    required this.empty,
  });

  final List<int> weeks;
  final Color color;
  final Color empty;

  Color _shade(int intakes) => switch (intakes) {
    0 => empty,
    1 => color.withValues(alpha: 0.75),
    2 => color.withValues(alpha: 0.875),
    _ => color,
  };

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      key: const Key('weekStrip'),
      spacing: 3,
      children: [
        for (final intakes in weeks)
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: _shade(intakes),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    ),
  );
}

class _NewSubstanceTile extends StatefulWidget {
  const _NewSubstanceTile();

  @override
  State<_NewSubstanceTile> createState() => _NewSubstanceTileState();
}

class _NewSubstanceTileState extends State<_NewSubstanceTile> {
  /// The row the new substance screen grows out of.
  final _row = GlobalKey();

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return OutlinedButton.icon(
      key: _row,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      onPressed: () => context.push(
        '/substance/new',
        extra: TransitionOrigin(key: _row, radius: _radius),
      ),
      icon: const Icon(Icons.add),
      label: Text(l.newSubstanceTile),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

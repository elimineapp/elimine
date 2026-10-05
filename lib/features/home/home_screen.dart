import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/motion/container_transform.dart';
import '../../app/providers.dart';
import '../../core/appearance.dart';
import '../../core/db/queries.dart';
import '../../core/l10n/format.dart';
import '../analytics/analytics.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/intake_tile.dart';
import '../../widgets/substance_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final substances = ref.watch(substancesProvider);
    final intakes = ref.watch(recentIntakesProvider);
    final archived = ref.watch(archivedSubstancesProvider).value ?? const [];
    final marks = ref.watch(weekMarksProvider);
    final today = DateFormat.MMMMEEEEd(l.localeName).format(DateTime.now());

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
      body: CustomScrollView(
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
              child: Text(l.recentTitle, style: theme.textTheme.titleMedium),
            ),
          ),
          switch (intakes) {
            AsyncData(value: final items) when items.isEmpty =>
              SliverToBoxAdapter(child: _Message(l.emptyIntakes)),
            AsyncData(value: final items) => SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
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
            AsyncError(:final error) => SliverToBoxAdapter(
              child: _Message('$error'),
            ),
            _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
          },
          // Out of the daily path: below everything else, only when needed.
          if (archived.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ListTile(
                  key: const Key('archiveEntry'),
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(l.archiveEntry(archived.length)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/archive'),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
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
class _SubstanceTile extends StatelessWidget {
  const _SubstanceTile({required this.item, required this.weeks});

  final SubstanceWithLast item;

  /// Intakes in each of the [markedWeeks] weeks, oldest first.
  final List<int> weeks;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (:substance, :last) = item;
    final color = context.substanceColorOf(substance.color);
    final dark = theme.brightness == Brightness.dark;
    final lastLabel = l.lastIntake(last, substance.unit, DateTime.now());

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

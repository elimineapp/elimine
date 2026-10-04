import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
              sliver: SliverList.separated(
                itemCount: items.length + 1,
                separatorBuilder: (context, i) => const SizedBox(height: 8),
                itemBuilder: (context, i) => i < items.length
                    ? _SubstanceTile(
                        item: items[i],
                        weeks: marks[items[i].substance.id] ?? noWeekMarks,
                      )
                    : const _NewSubstanceTile(),
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
              SubstanceBadge(
                color: substance.color,
                icon: substance.icon,
                filled: true,
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

class _NewSubstanceTile extends StatelessWidget {
  const _NewSubstanceTile();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => context.push('/substance/new'),
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

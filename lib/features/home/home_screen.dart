import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/db/queries.dart';
import '../../core/l10n/format.dart';
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
    final today = DateFormat.MMMMEEEEd(l.localeName).format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        actions: [
          IconButton(
            key: const Key('settingsAction'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settingsTitle,
            onPressed: () => context.push('/settings'),
          ),
        ],
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
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 124,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length + 1,
                itemBuilder: (context, i) => i < items.length
                    ? _SubstanceTile(item: items[i])
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

class _SubstanceTile extends StatelessWidget {
  const _SubstanceTile({required this.item});

  final SubstanceWithLast item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (:substance, :last) = item;
    final lastLabel = switch (last) {
      null => l.neverLogged,
      Intake(:final amount) => [
        if (amount != null) l.dose(amount, substance.unit),
        l.relativeDay(intakeWallTime(last), DateTime.now()),
      ].join(' · '),
    };

    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/substance/${substance.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubstanceBadge(color: substance.color, icon: substance.icon),
              const Spacer(),
              Text(
                substance.name,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                lastLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewSubstanceTile extends StatelessWidget {
  const _NewSubstanceTile();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/substance/new'),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [const Icon(Icons.add), Text(l.newSubstanceTile)],
          ),
        ),
      ),
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

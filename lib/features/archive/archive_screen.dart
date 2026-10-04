import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/db/queries.dart';
import '../../core/l10n/format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/substance_badge.dart';
import '../substance/delete_substance.dart';

enum _Action { restore, delete }

/// Archived substances: put one back on Home or delete it for good. Leaves
/// by itself once nothing is archived.
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  Future<void> _act(_Action action, SubstanceWithCount item) async {
    final s = item.substance;
    switch (action) {
      case _Action.restore:
        await ref.read(substanceServiceProvider).restore(s.id);
      case _Action.delete:
        await confirmAndDeleteSubstance(context, ref, id: s.id, name: s.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final archived = ref.watch(archivedSubstancesProvider);

    ref.listen(archivedSubstancesProvider, (_, next) {
      if (next case AsyncData(value: [])) {
        if (context.canPop()) context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l.archiveTitle)),
      body: switch (archived) {
        AsyncData(value: final items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final s = item.substance;
            return ListTile(
              leading: SubstanceBadge(color: s.color, icon: s.icon),
              title: Text(nameWithUnit(s)),
              subtitle: Text(l.entriesCount(item.intakes)),
              trailing: PopupMenuButton<_Action>(
                key: Key('archiveMenu-${s.id}'),
                onSelected: (action) => _act(action, item),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _Action.restore,
                    child: ListTile(
                      leading: const Icon(Icons.unarchive_outlined),
                      title: Text(l.restore),
                    ),
                  ),
                  PopupMenuItem(
                    value: _Action.delete,
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(l.delete),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}

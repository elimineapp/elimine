import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/l10n/format.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dose_chips.dart';
import '../../widgets/intake_time_field.dart';
import '../../widgets/substance_badge.dart';
import 'delete_intake.dart';

enum _Outcome { saved, deleted }

/// Opens the "Edit entry" sheet for [intake] and, once it closes, reports a
/// save or a deletion in a snackbar with "Undo" on the screen underneath.
Future<void> showEditIntakeSheet(
  BuildContext context,
  WidgetRef ref,
  Intake intake, {
  DateTime Function() clock = DateTime.now,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  // Read up front: the tile that opened the sheet may be gone once it closes,
  // e.g. when the new time moves the intake out of the loaded part of "History".
  final service = ref.read(intakeServiceProvider);

  final outcome = await showModalBottomSheet<_Outcome>(
    context: context,
    // Over the bottom navigation on Home, like the substance screen.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _EditIntakeSheet(intake: intake, clock: clock),
  );
  switch (outcome) {
    case _Outcome.saved:
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.intakeUpdated),
            action: SnackBarAction(
              label: l.undo,
              onPressed: () => service.revert(intake),
            ),
          ),
        );
    case _Outcome.deleted:
      deleteIntake(service, messenger, l, intake.id);
    case null:
  }
}

class _EditIntakeSheet extends ConsumerStatefulWidget {
  const _EditIntakeSheet({required this.intake, required this.clock});

  final Intake intake;
  final DateTime Function() clock;

  @override
  ConsumerState<_EditIntakeSheet> createState() => _EditIntakeSheetState();
}

class _EditIntakeSheetState extends ConsumerState<_EditIntakeSheet> {
  /// The intake's wall-clock time, as a local [DateTime] with the same fields
  /// so the time field reads it as is. Null means "Now".
  late DateTime? _at = () {
    final w = intakeWallTime(widget.intake);
    return DateTime(w.year, w.month, w.day, w.hour, w.minute, w.second);
  }();

  late double? _amount = widget.intake.amount;

  Future<void> _save() async {
    final changed = await ref
        .read(intakeServiceProvider)
        .edit(widget.intake, wallTime: _at, amount: _amount);
    if (mounted) Navigator.pop(context, changed ? _Outcome.saved : null);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.intake.substanceId;
    final substance = ref.watch(substanceProvider(id)).value;
    final doses = ref.watch(dosesProvider(id)).value ?? const [];
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.editIntakeTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (substance != null)
            Row(
              spacing: 12,
              children: [
                SubstanceBadge(
                  color: substance.color,
                  icon: substance.icon,
                  size: 32,
                ),
                Flexible(
                  child: Text(
                    substance.name,
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          IntakeTimeField(
            value: _at,
            clock: widget.clock,
            onChanged: (at) => setState(() => _at = at),
          ),
          const SizedBox(height: 24),
          Text(l.doseTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DoseChips(
            amounts: [for (final d in doses) d.amount],
            selected: _amount,
            unit: substance?.unit ?? '',
            onChanged: (amount) => setState(() => _amount = amount),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton.icon(
                key: const Key('deleteIntake'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_outline),
                label: Text(l.delete),
                onPressed: () => Navigator.pop(context, _Outcome.deleted),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('saveIntake'),
                onPressed: _save,
                child: Text(l.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

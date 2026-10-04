import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/database.dart';
import '../core/l10n/format.dart';
import '../app/providers.dart';
import '../features/intake/delete_intake.dart';
import '../features/intake/edit_intake_sheet.dart';
import '../l10n/app_localizations.dart';

/// One intake row. A tap opens the edit sheet; a swipe left soft-deletes it
/// with an undo snackbar.
class IntakeTile extends ConsumerWidget {
  const IntakeTile({
    super.key,
    required this.intake,
    required this.unit,
    this.leading,
    this.title,
    this.clock = DateTime.now,
  });

  final Intake intake;
  final String unit;
  final Widget? leading;

  /// Defaults to the intake time; the home screen shows the substance here.
  final String? title;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final time = l.intakeTime(intake, clock());

    return Dismissible(
      key: ValueKey(intake.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => deleteIntake(
        ref.read(intakeServiceProvider),
        ScaffoldMessenger.of(context),
        l,
        intake.id,
      ),
      child: ListTile(
        onTap: () => showEditIntakeSheet(context, ref, intake, clock: clock),
        leading: leading,
        title: Text(title ?? time),
        subtitle: title == null ? null : Text(time),
        trailing: switch (intake.amount) {
          final amount? => Text(
            l.dose(amount, unit),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          null => null,
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/db/database.dart';
import '../core/l10n/format.dart';
import '../l10n/app_localizations.dart';

/// One intake row. Swipe left soft-deletes it with an undo snackbar.
class IntakeTile extends ConsumerWidget {
  const IntakeTile({
    super.key,
    required this.intake,
    required this.unit,
    this.leading,
    this.title,
  });

  final Intake intake;
  final String unit;
  final Widget? leading;

  /// Defaults to the intake time; the home screen shows the substance here.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final time = l.intakeTime(intake, DateTime.now());

    return Dismissible(
      key: ValueKey(intake.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) {
        final service = ref.read(intakeServiceProvider);
        service.delete(intake.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l.intakeDeleted),
              action: SnackBarAction(
                label: l.undo,
                onPressed: () => service.restore(intake.id),
              ),
            ),
          );
      },
      child: ListTile(
        leading: leading,
        title: Text(title ?? time),
        subtitle: title == null ? null : Text(time),
        trailing: Text(
          l.dose(intake.amount, unit),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

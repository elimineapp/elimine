import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/queries.dart';
import '../../l10n/app_localizations.dart';

/// Asks to confirm, then deletes the substance with its doses and every
/// intake, and reports it in a snackbar. There is no undo, so the dialog
/// names the substance and how many entries go with it. Returns whether the
/// substance was deleted.
Future<bool> confirmAndDeleteSubstance(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String name,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final count = await ref.read(databaseProvider).countIntakes(id);
  if (!context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.deleteConfirmTitle(name)),
      content: Text(l.deleteConfirmBody(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        TextButton(
          key: const Key('confirmDelete'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  await ref.read(substanceServiceProvider).delete(id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l.substanceDeleted(name))));
  return true;
}

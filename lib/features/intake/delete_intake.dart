import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/intake_service.dart';

/// Soft-deletes an intake and offers "Undo" in a snackbar. Takes the
/// messenger rather than a context, so it also works after the edit sheet
/// that asked for it has closed.
void deleteIntake(
  IntakeService service,
  ScaffoldMessengerState messenger,
  AppLocalizations l,
  String id,
) {
  service.delete(id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l.intakeDeleted),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () => service.restore(id),
        ),
      ),
    );
}

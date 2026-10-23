import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/database.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the language, theme and lock before the first frame, so the app
  // never starts in the device's language and then switches, nor shows its
  // content before the lock screen.
  final db = AppDatabase();
  final settings = SettingsService(db);
  final preferences = await settings.readPreferences();
  final lock = await settings.readLock();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialPreferencesProvider.overrideWithValue(preferences),
        initialLockProvider.overrideWithValue(lock),
      ],
      child: const ElimineApp(),
    ),
  );
}

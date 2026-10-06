import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/db/database.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the language and theme before the first frame, so the app never
  // starts in the device's and then switches.
  final db = AppDatabase();
  final preferences = await SettingsService(db).readPreferences();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const ElimineApp(),
    ),
  );
}

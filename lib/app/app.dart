import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class ElimineApp extends ConsumerStatefulWidget {
  const ElimineApp({super.key});

  @override
  ConsumerState<ElimineApp> createState() => _ElimineAppState();
}

class _ElimineAppState extends ConsumerState<ElimineApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The home-screen widget writes through its own connection, which Drift
    // streams here cannot see. Re-query everything when the app comes back.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final db = ref.read(databaseProvider);
        db.markTablesUpdated(db.allTables);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3F6E5A);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      routerConfig: router,
    );
  }
}
